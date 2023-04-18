//
//  DatagroupParser.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import UIKit
import CryptoKit

@available(iOS 14.0, *)
public class DataGroup {

    /// Body contains the actual data
    public private(set) var body : [UInt8] = []

    /// Data contains the whole DataGroup data (as that is what the hash is calculated from
    public private(set) var data : [UInt8] = []

    var pos = 0
    
    required init( _ data : [UInt8] ) throws {
        self.data = data
        
        // Skip the first byte which is the header byte
        pos = 1
        let _ = try getNextLength()
        self.body = [UInt8](data[pos...])
        
        try parse(data)
    }
    
    func parse( _ data: [UInt8]) throws {
        throw NFCError.invalidCommand
    }
    
    func getNextTag() throws -> Int {
        var tag = 0
        if binToHex(data[pos]) & 0x0F == 0x0F {
            tag = Int(binToHex(data[pos..<pos+2]))
            pos += 2
        } else {
            tag = Int(data[pos])
            pos += 1
        }
        return tag
    }

    func getNextLength() throws -> Int  {
        let end = pos+4 < data.count ? pos+4 : data.count
        let (len, lenOffset) = try asn1Length([UInt8](data[pos..<end]))
        pos += lenOffset
        return len
    }
    
    func getNextValue() throws -> [UInt8] {
        let length = try getNextLength()
        let value = [UInt8](data[pos ..< pos+length])
        pos += length
        return value
    }
    
    public func hash( _ hashAlgorythm: String ) -> [UInt8]  {
        var ret : [UInt8] = []
        if hashAlgorythm == "SHA256" {
            ret = calcSHA256Hash(self.data)
        } else if hashAlgorythm == "SHA1" {
            ret = calcSHA1Hash(self.data)
        }
        
        return ret
    }

}

@available(iOS 14.0, *)
public class DataGroup1 : DataGroup {
    
    enum DocTypeEnum {
        case td1
        case td2
        case other
    }

    public private(set) var elements : [String:String] = [:]

    required init( _ data : [UInt8] ) throws {
        try super.init(data)
    }

    override func parse(_ data: [UInt8]) throws {
        let tag = try getNextTag()
        if tag != 0x5F1F {
            throw NFCError.invalidCommand
        }
        let body = try getNextValue()
        let docType = getMRZType(length:body.count)
        
        switch docType {
        case .td1:
            self.parseTd1(body)
        case .td2:
            self.parseTd2(body)
        default:
            self.parseOther(body)
        }
        
        // Store MRZ data
        elements["5F1F"] = String(bytes: body, encoding:.utf8)
    }
    
    func parseTd1(_ data : [UInt8]) {
        elements["5F03"] = String(bytes: data[0..<2], encoding:.utf8)
        elements["5F28"] = String( bytes:data[2..<5], encoding:.utf8)
        elements["5A"] = String( bytes:data[5..<14], encoding:.utf8)
        elements["5F04"] = String( bytes:data[14..<15], encoding:.utf8)
        elements["53"] = (String( bytes:data[15..<30], encoding:.utf8) ?? "") +
            (String( bytes:data[48..<59], encoding:.utf8) ?? "")
        elements["5F57"] = String( bytes:data[30..<36], encoding:.utf8)
        elements["5F05"] = String( bytes:data[36..<37], encoding:.utf8)
        elements["5F35"] = String( bytes:data[37..<38], encoding:.utf8)
        elements["59"] = String( bytes:data[38..<44], encoding:.utf8)
        elements["5F06"] = String( bytes:data[44..<45], encoding:.utf8)
        elements["5F2C"] = String( bytes:data[45..<48], encoding:.utf8)
        elements["5F07"] = String( bytes:data[59..<60], encoding:.utf8)
        elements["5B"] = String( bytes:data[60...], encoding:.utf8)
    }
    
    func parseTd2(_ data : [UInt8]) {
        elements["5F03"] = String( bytes:data[0..<2], encoding:.utf8)
        elements["5F28"] = String( bytes:data[2..<5], encoding:.utf8)
        elements["5B"] = String( bytes:data[5..<36], encoding:.utf8)
        elements["5A"] = String( bytes:data[36..<45], encoding:.utf8)
        elements["5F04"] = String( bytes:data[45..<46], encoding:.utf8)
        elements["5F2C"] = String( bytes:data[46..<49], encoding:.utf8)
        elements["5F57"] = String( bytes:data[49..<55], encoding:.utf8)
        elements["5F05"] = String( bytes:data[55..<56], encoding:.utf8)
        elements["5F35"] = String( bytes:data[56..<57], encoding:.utf8)
        elements["59"] = String( bytes:data[57..<63], encoding:.utf8)
        elements["5F06"] = String( bytes:data[63..<64], encoding:.utf8)
        elements["53"] = String( bytes:data[64..<71], encoding:.utf8)
        elements["5F07"] = String( bytes:data[71..<72], encoding:.utf8)
    }
    
    func parseOther(_ data : [UInt8]) {
        elements["5F03"] = String( bytes:data[0..<2], encoding:.utf8)
        elements["5F28"] = String( bytes:data[2..<5], encoding:.utf8)
        elements["5B"]   = String( bytes:data[5..<44], encoding:.utf8)
        elements["5A"]   = String( bytes:data[44..<53], encoding:.utf8)
        elements["5F04"] = String( bytes:[data[53]], encoding:.utf8)
        elements["5F2C"] = String( bytes:data[54..<57], encoding:.utf8)
        elements["5F57"] = String( bytes:data[57..<63], encoding:.utf8)
        elements["5F05"] = String( bytes:[data[63]], encoding:.utf8)
        elements["5F35"] = String( bytes:[data[64]], encoding:.utf8)
        elements["59"]   = String( bytes:data[65..<71], encoding:.utf8)
        elements["5F06"] = String( bytes:[data[71]], encoding:.utf8)
        elements["53"]   = String( bytes:data[72..<86], encoding:.utf8)
        elements["5F02"] = String( bytes:[data[86]], encoding:.utf8)
        elements["5F07"] = String( bytes:[data[87]], encoding:.utf8)
    }
    
    private func getMRZType(length: Int) -> DocTypeEnum {
        if length == 0x5A {
            return .td1
        }
        if length == 0x48 {
            return .td2
        }
        return .other
    }

}

@available(iOS 14.0, *)
public class DataGroup2: DataGroup {
    public private(set) var nrImages : Int = 0
    public private(set) var versionNumber : Int = 0
    public private(set) var lengthOfRecord : Int = 0
    public private(set) var numberOfFacialImages : Int = 0
    public private(set) var facialRecordDataLength : Int = 0
    public private(set) var nrFeaturePoints : Int = 0
    public private(set) var gender : Int = 0
    public private(set) var eyeColor : Int = 0
    public private(set) var hairColor : Int = 0
    public private(set) var featureMask : Int = 0
    public private(set) var expression : Int = 0
    public private(set) var poseAngle : Int = 0
    public private(set) var poseAngleUncertainty : Int = 0
    public private(set) var faceImageType : Int = 0
    public private(set) var imageDataType : Int = 0
    public private(set) var imageWidth : Int = 0
    public private(set) var imageHeight : Int = 0
    public private(set) var imageColorSpace : Int = 0
    public private(set) var sourceType : Int = 0
    public private(set) var deviceType : Int = 0
    public private(set) var quality : Int = 0
    public private(set) var imageData : [UInt8] = []
    
    func getImage() -> UIImage? {
        if imageData.count == 0 {
            return nil
        }
        
        let image = UIImage(data:Data(imageData) )
        return image
    }
    
    required init( _ data : [UInt8] ) throws {
        try super.init(data)
    }
    
    override func parse(_ data: [UInt8]) throws {
        var tag = try getNextTag()
        if tag != 0x7F61 {
            throw NFCError.invalidCommand
        }
        _ = try getNextLength()
        
        // Tag should be 0x02
        tag = try getNextTag()
        if  tag != 0x02 {
            throw NFCError.invalidCommand
        }
        nrImages = try Int(getNextValue()[0])

        // Next tag is 0x7F60
        tag = try getNextTag()
        if tag != 0x7F60 {
            throw NFCError.invalidCommand
        }
        _ = try getNextLength()

        // Next tag is 0xA1 (Biometric Header Template) - don't care about this
        tag = try getNextTag()
        if tag != 0xA1 {
            throw NFCError.invalidCommand
        }
        _ = try getNextValue()

        // Now we get to the good stuff - next tag is either 5F2E or 7F2E
        tag = try getNextTag()
        if tag != 0x5F2E && tag != 0x7F2E {
            throw NFCError.invalidCommand
        }
        let value = try getNextValue()

        try parseISO19794_5( data:value )
    }
    
    func parseISO19794_5( data : [UInt8] ) throws {
        // Validate header - 'F', 'A' 'C' 0x00 - 0x46414300
        if data[0] != 0x46 && data[1] != 0x41 && data[2] != 0x43 && data[3] != 0x00 {
            throw NFCError.invalidCommand
        }
        
        var offset = 4
        versionNumber = binToInt(data[offset..<offset+4])
        offset += 4
        lengthOfRecord = binToInt(data[offset..<offset+4])
        offset += 4
        numberOfFacialImages = binToInt(data[offset..<offset+2])
        offset += 2
        
        facialRecordDataLength = binToInt(data[offset..<offset+4])
        offset += 4
        nrFeaturePoints = binToInt(data[offset..<offset+2])
        offset += 2
        gender = binToInt(data[offset..<offset+1])
        offset += 1
        eyeColor = binToInt(data[offset..<offset+1])
        offset += 1
        hairColor = binToInt(data[offset..<offset+1])
        offset += 1
        featureMask = binToInt(data[offset..<offset+3])
        offset += 3
        expression = binToInt(data[offset..<offset+2])
        offset += 2
        poseAngle = binToInt(data[offset..<offset+3])
        offset += 3
        poseAngleUncertainty = binToInt(data[offset..<offset+3])
        offset += 3
        
        // Features (not handled). There shouldn't be any but if for some reason there were,
        // then we are going to skip over them
        // The Feature block is 8 bytes
        offset += nrFeaturePoints * 8

        faceImageType = binToInt(data[offset..<offset+1])
        offset += 1
        imageDataType = binToInt(data[offset..<offset+1])
        offset += 1
        imageWidth = binToInt(data[offset..<offset+2])
        offset += 2
        imageHeight = binToInt(data[offset..<offset+2])
        offset += 2
        imageColorSpace = binToInt(data[offset..<offset+1])
        offset += 1
        sourceType = binToInt(data[offset..<offset+1])
        offset += 1
        deviceType = binToInt(data[offset..<offset+2])
        offset += 2
        quality = binToInt(data[offset..<offset+2])
        offset += 2

        
        // Make sure that the image data at least has a valid header
        // Either JPG or JPEG2000
        let jpegHeader : [UInt8] = [0xff,0xd8,0xff,0xe0,0x00,0x10,0x4a,0x46,0x49,0x46]
        let jpeg2000BitmapHeader : [UInt8] = [0x00,0x00,0x00,0x0c,0x6a,0x50,0x20,0x20,0x0d,0x0a]
        let jpeg2000CodestreamBitmapHeader : [UInt8] = [0xff,0x4f,0xff,0x51]

        if [UInt8](data[offset..<offset+jpegHeader.count]) != jpegHeader &&
            [UInt8](data[offset..<offset+jpeg2000BitmapHeader.count]) != jpeg2000BitmapHeader &&
            [UInt8](data[offset..<offset+jpeg2000CodestreamBitmapHeader.count]) != jpeg2000CodestreamBitmapHeader {
            throw NFCError.invalidCommand
        }

        imageData = [UInt8](data[offset...])
    }
}



@available(iOS 14.0, *)
public class DataGroup11: DataGroup {
    
    public private(set) var fullName : String?
    public private(set) var personalNumber : String?
    public private(set) var dateOfBirth : String?
    public private(set) var placeOfBirth : String?
    public private(set) var address : String?
    public private(set) var telephone : String?
    public private(set) var profession : String?
    public private(set) var title : String?
    public private(set) var personalSummary : String?
    public private(set) var proofOfCitizenship : String?
    public private(set) var tdNumbers : String?
    public private(set) var custodyInfo : String?

    required init( _ data : [UInt8] ) throws {
        try super.init(data)
    }
        
    override func parse(_ data: [UInt8]) throws {
        var tag = try getNextTag()
        if tag != 0x5C {
            throw NFCError.invalidCommand
        }
        _ = try getNextValue()
        
        repeat {
            tag = try getNextTag()
            let val = try String( bytes:getNextValue(), encoding:.utf8)
            if tag == 0x5F0E {
                fullName = val
            } else if tag == 0x5F10 {
                personalNumber = val
            } else if tag == 0x5F11 {
                placeOfBirth = val
            } else if tag == 0x5F2B {
                dateOfBirth = val
            } else if tag == 0x5F42 {
                address = val
            } else if tag == 0x5F12 {
                telephone = val
            } else if tag == 0x5F13 {
                profession = val
            } else if tag == 0x5F14 {
                title = val
            } else if tag == 0x5F15 {
                personalSummary = val
            } else if tag == 0x5F16 {
                proofOfCitizenship = val
            } else if tag == 0x5F18 {
                tdNumbers = val
            } else if tag == 0x5F18 {
                custodyInfo = val
            }
        } while pos < data.count
    }
}

@available(iOS 14.0, *)
public class DataGroup12 : DataGroup {
    
    public private(set) var issuingAuthority : String?
    public private(set) var dateOfIssue : String?
    public private(set) var otherPersonsDetails : String?
    public private(set) var endorsementsOrObservations : String?
    public private(set) var taxOrExitRequirements : String?
    public private(set) var frontImage : [UInt8]?
    public private(set) var rearImage : [UInt8]?
    public private(set) var personalizationTime : String?
    public private(set) var personalizationDeviceSerialNr : String?
    
    required init( _ data : [UInt8] ) throws {
        try super.init(data)
    }
    
    override func parse(_ data: [UInt8]) throws {
        var tag = try getNextTag()
        if tag != 0x5C {
            throw NFCError.invalidCommand
        }
        
        // Skip the taglist - ideally we would check this but...
        let _ = try getNextValue()
        
        repeat {
            tag = try getNextTag()
            let val = try getNextValue()
            
            if tag == 0x5F19 {
                issuingAuthority = String( bytes:val, encoding:.utf8)
            } else if tag == 0x5F26 {
                dateOfIssue = parseDateOfIssue(value: val)
            } else if tag == 0xA0 {
                // Not yet handled
            } else if tag == 0x5F1B {
                endorsementsOrObservations = String( bytes:val, encoding:.utf8)
            } else if tag == 0x5F1C {
                taxOrExitRequirements = String( bytes:val, encoding:.utf8)
            } else if tag == 0x5F1D {
                frontImage = val
            } else if tag == 0x5F1E {
                rearImage = val
            } else if tag == 0x5F55 {
                personalizationTime = String( bytes:val, encoding:.utf8)
            } else if tag == 0x5F56 {
                personalizationDeviceSerialNr = String( bytes:val, encoding:.utf8)
            }
        } while pos < data.count
    }
    
    private func parseDateOfIssue(value: [UInt8]) -> String? {
        if value.count == 4 {
            return decodeBCD(value: value)
        } else {
            return decodeASCII(value: value)
        }
    }
    
    private func decodeASCII(value: [UInt8]) -> String? {
        return String(bytes:value, encoding:.utf8)
    }
    
    private func decodeBCD(value: [UInt8]) -> String? {
        value.map({ String(format: "%02X", $0) }).joined()
    }
}

private func binToHex( _ val: UInt8 ) -> Int {
    let hexRep = String(format:"%02X", val)
    return Int(hexRep, radix:16)!
}

private func binToHex( _ val: [UInt8] ) -> UInt64 {
    let hexVal = UInt64(binToHexRep(val), radix:16)!
    return hexVal
}

private func binToHex( _ val: ArraySlice<UInt8> ) -> UInt64 {
    return binToHex( [UInt8](val) )
}

private func binToInt( _ val: ArraySlice<UInt8> ) -> Int {
    let hexVal = binToInt( [UInt8](val) )
    return hexVal
}

private func binToInt( _ val: [UInt8] ) -> Int {
    let hexVal = Int(binToHexRep(val), radix:16)!
    return hexVal
}

private func binToHexRep( _ val : [UInt8] ) -> String {
    var string = ""
    for x in val {
        string += String(format:"%02x", x )
    }
    return string.uppercased()
}

private func binToHexRep( _ val : UInt8 ) -> String {
    let string = String(format:"%02x", val ).uppercased()
    return string
}

private func asn1Length( _ data: ArraySlice<UInt8> ) throws -> (Int, Int) {
    return try asn1Length( Array(data) )
}

private func asn1Length(_ data : [UInt8]) throws -> (Int, Int)  {
    if data[0] <= 0x7F {
        return (Int(binToHex(data[0])), 1)
    }
    if data[0] == 0x81 {
        return (Int(binToHex(data[1])), 2)
    }
    if data[0] == 0x82 {
        let val = binToHex([UInt8](data[1..<3]))
        return (Int(val), 3)
    }
    
    throw NFCError.invalidCommand
    
}

@available(iOS 14.0, *)
private func calcSHA256Hash( _ data: [UInt8] ) -> [UInt8] {
    #if canImport(CryptoKit)
    var sha1 = SHA256()
    sha1.update(data: data)
    let hash = sha1.finalize()
    
    return Array(hash)
    #else
    fatalError("Couldn't import CryptoKit")
    #endif
}

@available(iOS 14.0, *)
private func calcSHA1Hash( _ data: [UInt8] ) -> [UInt8] {
    #if canImport(CryptoKit)
    var sha1 = Insecure.SHA1()
    sha1.update(data: data)
    let hash = sha1.finalize()
    
    return Array(hash)
    #else
    fatalError("Couldn't import CryptoKit")
    #endif
}
