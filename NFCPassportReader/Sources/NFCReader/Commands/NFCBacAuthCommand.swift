//
//  NFCBacAuthCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

struct BacAuthResult {
    let apduMutua: Data
    let bacEnc: Data
    let bacMac: Data
    let kIs: Data
}

@available(iOS 14.0, *)
class NFCBacAuthCommand: NFCCommand {
    
    private let mrzData: MRZData
    
    init(mrzData: MRZData) {
        self.mrzData = mrzData
    }
    
    func performCommand(context: NFCCommandContext, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void) {
        
        guard let apduChallenge = NFCISO7816APDU(data: "0084000008".hexaData) else {
            completion(.failure(.invalidCommand))
            return
        }
        
        context.tag.sendCommand(apdu: apduChallenge) { [weak self] (response, status1, status2, error) in
            
            let responseCode = String(format: "%02x%02x", status1, status2)
            guard responseCode == "9000" else {
                completion(.failure(.invalidCommand))
                return
            }
            
            guard let mrzData = self?.mrzData else {
                completion(.failure(.invalidCommand))
                return
            }
            
            var birthDate = mrzData.birthDate.data
            var expiration = mrzData.expirationDate.data
            var cardIdData = mrzData.documentNumber.data
            
            // add checks
            guard let cardIdCheck = Functions.digit(data: cardIdData) else {
                completion(.failure(.invalidCommand))
                return
            }
            cardIdData.append(cardIdCheck)
            
            guard let birthCheck = Functions.digit(data: birthDate) else {
                completion(.failure(.invalidCommand))
                return
            }
            birthDate.append(birthCheck)
            
            guard let expirationCheck = Functions.digit(data: expiration) else {
                completion(.failure(.invalidCommand))
                return
            }
            expiration.append(expirationCheck)
            
            // concatenation
            cardIdData.append(birthDate)
            cardIdData.append(expiration)
            
            let concatenationSha = cardIdData.sha1
            
            var bacEnc = concatenationSha.prefix(16)
            bacEnc.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
            bacEnc = bacEnc.sha1.prefix(16)
            
            var bacMac = concatenationSha.prefix(16)
            bacMac.append(contentsOf: [0x00, 0x00, 0x00, 0x02])
            bacMac = bacMac.sha1.prefix(16)
            
            guard var rndIs1 = Functions.generateRandomBytes(count: 8) else {
                completion(.failure(.invalidCommand))
                return
            }
            guard let kIs = Functions.generateRandomBytes(count: 16) else {
                completion(.failure(.invalidCommand))
                return
            }
            
            rndIs1.append(response)
            rndIs1.append(kIs)
            
            let eIs1 = Algorithms.tripleDesEncrypt(key: bacEnc.bytes, data: rndIs1)!
            let eIs1IsoPad = Algorithms.getIsoPad(data: eIs1)!
            let eIsMac = Algorithms.macEnc(masterKey: bacMac, data: eIs1IsoPad)!
            
            var apduMutaAuth = Data([0x00, 0x82, 0x00, 0x00, 0x28])
            apduMutaAuth.append(eIs1)
            apduMutaAuth.append(eIsMac)
            apduMutaAuth.append(0x28)
            
            let result = BacAuthResult(apduMutua: apduMutaAuth, bacEnc: bacEnc, bacMac: bacMac, kIs: kIs)
            completion(.success(.init(tag: context.tag, parameter: .bacResult(result))))
        }
    }
}
