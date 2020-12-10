//
//  NFCCommandUtils.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation

@available(iOS 14.0, *)
class NFCCommandUtils {
    
    static func seqIncrement(seq: inout [UInt8], index: Int? = nil) {

        if index == nil {
            return seqIncrement(seq: &seq, index: seq.count - 1)
        }

        if seq[index!] == 0xFF {
            seq[index!] = 0
            seqIncrement(seq: &seq, index: index! - 1)
        } else {
            seq[index!] += 1
        }

    }
    
    static func respSecureMessage(sessionKeys: SessionKeys,
                                          resp: [UInt8],
                                          odd: Bool = false) -> ([UInt8], SessionKeys)? {

        var seq = sessionKeys.seq
        NFCCommandUtils.seqIncrement(seq: &seq)

        var index: Int = 0
        updateIndex(index: &index, args: 0)

        var encData: [UInt8] = []
        var encObj: [UInt8] = []
        var dataObj: [UInt8] = []

        let lenResp = resp.count
        var firstPass = true
        while firstPass || index < lenResp {
            firstPass = false

            if resp[index] == 0x99 {
                if resp[index + 1] != 0x02 {
                    fatalError()
                }
                dataObj = resp[index..<index + 4] + []
                updateIndex(index: &index, args: index, 4)
                continue
            }

            if resp[index] == 0x8e {
                
                guard let iso = Algorithms.getIsoPad(data: Data(seq + encObj + dataObj)) else {
                    return nil
                }
                guard let calcMac = Algorithms.macEnc(masterKey: Data(sessionKeys.kSessMac), data: iso) else {
                    return nil
                }
                updateIndex(index: &index, args: index + 1)

                if resp[index] != 0x08 {
                    fatalError()
                }
                updateIndex(index: &index, args: index, 1)
                if calcMac.bytes != (resp[index..<index + 8] + []) {
                    fatalError()
                }
                updateIndex(index: &index, args: index, 8)
                continue
            }

            if resp[index] == 0x87 {
                if resp[index + 1] > 0x80 {
                    var lgn: UInt8 = 0
                    let llen = resp[index + 1] - 0x80
                    if llen == 1 {
                        lgn = resp[index + 2]
                    } else if llen == 2 {
                        lgn = (resp[index + 2] << 8) | resp[index + 3]
                    }

                    let upperIndex = index + Int(llen) + Int(lgn) + 2
                    encObj = resp[index..<upperIndex] + []

                    let encDataLow = index + Int(llen) + 3
                    let encDataHight = index + Int(llen) + 2 + Int(lgn)
                    encData = resp[encDataLow..<encDataHight] + []

                    updateIndex(index: &index, args: index, Int(llen), Int(lgn), 2)

                } else {
                    let respIncr = Int(resp[index + 1])
                    let encObjHigh = index + respIncr + 2
                    encObj = resp[index..<encObjHigh] + []

                    let encDataLow = index + 3
                    let encDataHigh = index + 2 + Int(resp[index + 1])
                    encData = resp[encDataLow..<encDataHigh] + []

                    updateIndex(index: &index, args: index, Int(resp[index + 1]), 2)
                }
                continue
            }

            if resp[index] == 0x85 {
                if resp[index + 1] > 0x80 {
                    var lgn: UInt8 = 0
                    let llen = resp[index + 1] - 0x80
                    if llen == 1 {
                        lgn = resp[index + 2]
                    } else if llen == 2 {
                        lgn = (resp[index + 2] << 8) | resp[index + 3]
                    }

                    let encObjUp: Int = index + Int(llen) + Int(lgn) + 2
                    encObj = resp[index..<encObjUp] + []

                    let eDataLowIdx = index + Int(llen) + 2
                    let eDataHighIdx = index + Int(llen) + 2 + Int(lgn)
                    encData = resp[eDataLowIdx..<eDataHighIdx] + []
                    updateIndex(index: &index, args: index, Int(llen), Int(lgn), 2)

                } else {
                    let encObjHIndex = index + Int(resp[index + 1]) + 2
                    encObj = resp[index..<encObjHIndex] + []

                    let encDataHIndex = index + 2 + Int(resp[index + 1])
                    encData = resp[index + 2..<encDataHIndex] + []
                    updateIndex(index: &index, args: index, Int(resp[index + 1]), 2)
                }
                continue
            }

            print("unknown ASN.1 tag")
            return nil
        }

        guard !encData.isEmpty && !odd else {
           return nil
        }
        
        guard let desDec = Algorithms.tripleDesDecrypt(key: sessionKeys.kSessEnc, data: Data(encData)) else {
            return nil
        }
        
        guard let isoRemove = Algorithms.isoRemove(data: desDec)?.bytes else {
            return nil
        }
        
        return (isoRemove, sessionKeys.with(newSeq: seq))

    }
    
    static func secureMessage(apdu: [UInt8], response: SessionKeys) -> ([UInt8], SessionKeys)? {

        var seq = response.seq
        NFCCommandUtils.seqIncrement(seq: &seq)

        guard var calcMac = Algorithms.getIsoPad(data: Data(seq + apdu.prefix(4))) else {
            return nil
        }

        var doob: [UInt8]
        var dataField: [UInt8] = []

        if apdu[4] != 0 && apdu.count > 5 {
            let apduToIso = apdu[5..<5 + Int(apdu[4])]
            guard let apduIso = Algorithms.getIsoPad(data: Data(apduToIso)) else {
                return nil
            }
            guard let enc = Algorithms.tripleDesEncrypt(key: response.kSessEnc, data: apduIso) else {
                return nil
            }

            if apdu[1] % 2 == 0 {
                doob = Functions.asn1Tag(array: [0x01] + enc.bytes, tag: 0x87)!
            } else {
                doob = Functions.asn1Tag(array: enc.bytes, tag: 0x85)!
            }

            calcMac += doob
            dataField = dataField.isEmpty ? doob : dataField + doob

        }

        if apdu.count == 5 || apdu.count == apdu[4] + 6 {
            doob = [0x97, 0x01, apdu.last!]
            calcMac = calcMac + doob

            if dataField.isEmpty {
                dataField = [] + doob
            } else {
                dataField += doob
            }
        }

        guard let isoPad = Algorithms.getIsoPad(data: calcMac) else {
            return nil
        }
        guard let smMac = Algorithms.macEnc(masterKey: Data(response.kSessMac), data: isoPad) else {
            return nil
        }
        dataField = dataField + [0x8e, 0x08] + smMac
        
        let final: [UInt8] = [] + apdu.prefix(4) + [UInt8(dataField.count)] + dataField + [0x00]

        return (final, response.with(newSeq: seq))

    }
    
    private static func updateIndex(index: inout Int, args: Int...) {
        
        var tmpIndex: Int = 0
        for arg in args {
            if arg < 0 {
                tmpIndex += arg & 0xFF
            } else {
                tmpIndex += arg
            }
        }
        index = tmpIndex
        
    }
    
}
