//
//  Functions.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation

class Functions {
    
    static func digit(data: Data) -> Data? {
        
        var tot: Int = 0
        var curval: UInt8 = 0
        let weigth: [Int] = [7, 3, 1]
        
        for i in 0..<data.bytes.count {
            let byte = data.bytes[i]
            let ch = Character.init(UnicodeScalar.init(byte)).uppercased().utf8.first!
            
            if ch >= "A".utf8.first! && ch <= "Z".utf8.first! {
                curval = ch - "A".utf8.first! + UInt8(10)
            } else {
                if ch >= "0".utf8.first! && ch <= "9".utf8.first! {
                    curval = ch - "0".utf8.first!
                } else {
                    if ch == "<".utf8.first! {
                        curval = 0
                    } else {
                        return nil
                    }
                }
            }
            tot += (Int(curval) * weigth[i % 3])
        }
        
        tot = tot % 10
        let res = "0".utf8.first! + UInt8(tot)
        return Data([res])
        
    }
    
    static func generateRandomBytes(count: Int) -> Data? {

        let bytes = [UInt32](repeating: 0, count: count).map { _ in arc4random() }
        let data = Data(bytes: bytes, count: count)
        return data
    }
    
    static func asn1Tag(array: [UInt8], tag: Int) -> [UInt8]? {
        
        let tag = tagToByte(value: tag)
        let len = lenToByte(value: array.count)
        let data = tag + len + array
        return data
        
    }
    
    static func tagToByte(value: Int) -> [UInt8] {
        
        if value <= 0xff {
            return [value].map(UInt8.init)
        
        } else if value <= 0xffff {
            return [value >> 8, value & 0xff].map(UInt8.init)
        
        } else if value <= 0xffffff {
            return [value >> 16, ((value >> 8) & 0xff), (value & 0xff)].map(UInt8.init)
        
        } else if value <= 0xffffffff {
            return [(value >> 24), ((value >> 16) & 0xff), ((value >> 8) & 0xff), (value & 0xff)].map(UInt8.init)
        }
        
        fatalError("Tag is too big")
    }
    
    static func lenToByte(value: Int) -> [UInt8] {
        
        if value < 0x80 {
            return [value].map(UInt8.init)
        }
                
        if value <= 0xff {
            return [0x81, value].map(UInt8.init)
        } else if value <= 0xffff {
            return [0x82, value >> 8, value & 0xff].map(UInt8.init)
        } else if value <= 0xffffff {
            return [0x83, (value >> 16), ((value >> 8) & 0xff), (value & 0xff)].map(UInt8.init)
        } else if value <= 0xffffffff {
            return [0x84, (value >> 24), ((value >> 16) & 0xff), ((value >> 8) & 0xff), (value & 0xff)].map(UInt8.init)
        }
        
        fatalError("Value is too big")
    }
    
}
