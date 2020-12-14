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
class NFCReadDGCommand: NFCCommand {
    
    enum DataGroup: UInt8 {
        case dg1 = 1
        case dg2 = 2
        case dg11 = 11
    }
    
    private let dataGroup: DataGroup
    
    init(dataGroup: DataGroup) {
        self.dataGroup = dataGroup
    }
    
    func performCommand(tag: NFCISO7816Tag, sessionKeys: SessionKeys?, param: Any?) -> SignalProducer<(NFCISO7816Tag, SessionKeys?, Any?), NFCError> {
        
        guard let sessionKeys = sessionKeys else {
            return .init(error: .invalidCommand)
        }
        
        return SignalProducer { [weak self] observer, lifetime in
            
            guard let dataGroup = self?.dataGroup else {
                observer.send(error: .invalidCommand)
                return
            }
            
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
                
                guard let maxLen = NFCReadDGCommand.parseLength(data: secureResponse) else {
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
