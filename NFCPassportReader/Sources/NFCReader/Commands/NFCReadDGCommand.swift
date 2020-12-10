//
//  NFCReadDGCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import CoreNFC
import ReactiveSwift

@available(iOS 14.0, *)
class NFCReadDGCommand {
    
    enum DataGroup: UInt8 {
        case dg2 = 2
        case dg11 = 11
    }
    
    static func performCommand(tag: NFCISO7816Tag,
                               dataGroup: DataGroup,
                               sessionKeys: SessionKeys)
    -> SignalProducer<(NFCISO7816Tag, SessionKeys, Int), NFCError> {
        
        return SignalProducer { observer, lifetime in
            
            let somma: UInt8 = dataGroup.rawValue + 0x80

            let appo: [UInt8] = [0x0C, 0xB0, somma, 0x00, 0x06]
            
            guard let secureMessage = NFCCommandUtils.secureMessage(apdu: appo, response: sessionKeys) else {
                observer.send(error: .invalidCommand)
                return
            }
            
            let newKeys = secureMessage.1

            guard let apduDG = NFCISO7816APDU(data: Data(secureMessage.0)) else {
                observer.send(error: .invalidCommand)
                return
            }

            tag.sendCommand(apdu: apduDG) { (resp, word1, word2, error) in

                let responseCode = String(format: "%02x%02x", word1, word2)
                guard responseCode == "9000" else {
                    observer.send(error: .invalidCommand)
                    return
                }

                guard let chunkLen = NFCCommandUtils.respSecureMessage(sessionKeys: newKeys, resp: resp.bytes) else {
                    observer.send(error: .invalidCommand)
                    return
                }
                
                let secureResponse = chunkLen.0
                let newKeys = chunkLen.1
                
                guard let maxLen = parseLength(data: secureResponse) else {
                    observer.send(error: .invalidCommand)
                    return
                }
                
                observer.send(value: (tag, newKeys, maxLen))
                observer.sendCompleted()

            }
        }
        
    }
    
    private static func parseLength(data: [UInt8]) -> Int? {

        let dataLen = data.count

        if dataLen == 0 {
            return nil
        }

        var readPos = 2

        var byteLen = Int(data[1])
        if byteLen > 128 {
            let lenlen = byteLen - 128
            byteLen = 0
            for _ in 0..<lenlen {
                if readPos == dataLen {
                    return nil
                }

                byteLen = (byteLen << 8) | Int(data[readPos])
                readPos += 1
            }
        }
        return readPos + byteLen

    }
    
}
