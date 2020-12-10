//
//  NFCBacAuthCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import CoreNFC
import ReactiveSwift

@available(iOS 14.0, *)
class NFCBacAuthCommand {
    
    struct BacAuthResult {
        let apduMutua: Data
        let bacEnc: Data
        let bacMac: Data
        let kIs: Data
    }
    
    static func performCommand(tag: NFCISO7816Tag, mrzData: MRZData) -> SignalProducer<(NFCISO7816Tag, BacAuthResult), NFCError> {
        
        return SignalProducer { observer, lifetime in
            
            guard let apduChallenge = NFCISO7816APDU(data: "0084000008".hexaData) else {
                observer.send(error: .invalidCommand)
                return
            }

            tag.sendCommand(apdu: apduChallenge) { (response, status1, status2, error) in

                let responseCode = String(format: "%02x%02x", status1, status2)
                guard responseCode == "9000" else {
                    observer.send(error: .invalidCommand)
                    return
                }

                var birthDate = mrzData.birthDate.data
                var expiration = mrzData.expirationDate.data
                var cardIdData = mrzData.documentNumber.data

                // add checks
                guard let cardIdCheck = Functions.digit(data: cardIdData) else {
                    observer.send(error: .invalidCommand)
                    return
                }
                cardIdData.append(cardIdCheck)

                guard let birthCheck = Functions.digit(data: birthDate) else {
                    observer.send(error: .invalidCommand)
                    return
                }
                birthDate.append(birthCheck)

                guard let expirationCheck = Functions.digit(data: expiration) else {
                    observer.send(error: .invalidCommand)
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
                    observer.send(error: .invalidCommand)
                    return
                }
                guard let kIs = Functions.generateRandomBytes(count: 16) else {
                    observer.send(error: .invalidCommand)
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
                observer.send(value: (tag, result))
                observer.sendCompleted()

            }
        }
        
    }
    
}
