//
//  NFCExtractDataCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import CoreNFC
import ReactiveSwift

@available(iOS 14.0, *)
class NFCExtractDataCommand {
    
    static func performCommand(tag: NFCISO7816Tag,
                               sessionKeys: SessionKeys,
                               maxLength: Int) -> SignalProducer<(NFCISO7816Tag, Data, SessionKeys), NFCError> {
            
            return SignalProducer { observer, lifetime in
                
                extract(tag: tag, maxLength: maxLength, keys: sessionKeys) { (result) in
                    switch result {
                    case .success(let data):
                        observer.send(value: (tag, data.0, data.1))
                        observer.sendCompleted()
                    case .failure(let error):
                        observer.send(error: error)
                    }
                }
                
            }
    }
    
    private static func extract(tag: NFCISO7816Tag,
                                data: Data = Data(),
                                maxLength: Int,
                                keys: SessionKeys,
                                completion: @escaping (Result<(Data, SessionKeys), NFCError>) -> Void) {
        
        var internalData = data
        let internalDataCount = internalData.count
        var dataLen = internalData.count

        let readLen = min(0xe0, Int(maxLength - internalData.count))
        let fraction = UInt8(internalData.count / 256)
        let appo2: [UInt8] = [0x0C, 0xB0] as [UInt8] + [fraction & 0x7F, UInt8(internalDataCount & 0xFF), UInt8(readLen)]
        
        guard let secureMessage = NFCCommandUtils.secureMessage(apdu: appo2, response: keys) else {
            return
        }
        
        let apduDg = secureMessage.0
        let newKeys = secureMessage.1

        
        guard let apduDG = NFCISO7816APDU(data: Data(apduDg)) else {
            return
        }
        
        tag.sendCommand(apdu: apduDG) { (res2, word1, word2, error) in
            let responseCode = String(format: "%02x%02x", word1, word2)
            guard responseCode == "9000" else {
                completion(.failure(.invalidCommand))
                return
            }
            
            guard let secureResponse = NFCCommandUtils.respSecureMessage(sessionKeys: newKeys, resp: res2.bytes) else {
                completion(.failure(.invalidCommand))
                return
            }
            
            let chunk = secureResponse.0
            let newK = secureResponse.1
            
            internalData += chunk
            dataLen += chunk.count

            if dataLen < maxLength {
                extract(tag: tag, data: internalData, maxLength: maxLength, keys: newK, completion: completion)
            } else {
                completion(.success((internalData, newK)))
            }
        }
        
    }
    
}
