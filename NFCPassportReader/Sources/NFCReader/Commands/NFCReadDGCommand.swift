//
//  NFCReadDGCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

@available(iOS 14.0, *)
class NFCReadDGCommand: NFCCommand {
    
    enum DataGroup: UInt8 {
        case dg1 = 1
        case dg2 = 2
        case dg11 = 11
        case dg12 = 12
    }
    
    private let dataGroup: DataGroup
    
    init(dataGroup: DataGroup) {
        self.dataGroup = dataGroup
    }
    
    func performCommand(context: NFCCommandContext, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void) {

        let dataGroup = self.dataGroup
        let somma: UInt8 = dataGroup.rawValue + 0x80
        let appo: [UInt8] = [0x0C, 0xB0, somma, 0x00, 0x06]
        
        guard let sessionKeys = context.sessionKey,
              let secureMessage = NFCCommandUtils.secureMessage(apdu: appo, response: sessionKeys) else {
            completion(.failure(.invalidCommand))
            return
        }
        
        let newKeys = secureMessage.sessionKey
        
        guard let apduDG = NFCISO7816APDU(data: Data(secureMessage.messageSignature)) else {
            completion(.failure(.invalidCommand))
            return
        }
        
        context.tag.sendCommand(apdu: apduDG) { (resp, word1, word2, error) in
            
            let responseCode = String(format: "%02x%02x", word1, word2)
            guard responseCode == "9000" else {
                completion(.failure(.invalidCommand))
                return
            }
            
            guard let chunkLen = NFCCommandUtils.respSecureMessage(sessionKeys: newKeys, resp: resp.bytes) else {
                completion(.failure(.invalidCommand))
                return
            }
            
            let secureResponse = chunkLen.messageSignature
            let newKeys = chunkLen.sessionKey
            
            guard let maxLenght = NFCReadDGCommand.parseLength(data: secureResponse) else {
                completion(.failure(.invalidCommand))
                return
            }
            
            completion(.success(.init(tag: context.tag, sessionKey: newKeys, parameter: .parseLenght(maxLenght))))
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
