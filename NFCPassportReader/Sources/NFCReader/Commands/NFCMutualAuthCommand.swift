//
//  NFCMutualAuthCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import CoreNFC
import ReactiveSwift

@available(iOS 14.0, *)
class NFCMutualAuthCommand {
    
    static func performCommand(tag: NFCISO7816Tag, response: NFCBacAuthCommand.BacAuthResult) -> SignalProducer<(NFCISO7816Tag, SessionKeys), NFCError> {
        
        return SignalProducer { observer, lifetime in
            
            guard let apduChallenge = NFCISO7816APDU(data: response.apduMutua) else {
                observer.send(error: .invalidCommand)
                return
            }

            tag.sendCommand(apdu: apduChallenge) { (data, word1, word2, error) in

                let responseCode = String(format: "%02x%02x", word1, word2)
                guard responseCode == "9000" else {
                    observer.send(error: .invalidCommand)
                    return
                }

                let responseMutuaAuth = data.prefix(32)
                let kIsMacPad = Algorithms.getIsoPad(data: responseMutuaAuth)!
                let kIsMac = Algorithms.macEnc(masterKey: response.bacMac, data: kIsMacPad)
                let kIsMac2 = data.suffix(8)

                guard kIsMac == kIsMac2 else {
                    observer.send(error: .invalidCommand)
                    return
                }

                guard let decResp = Algorithms.tripleDesDecrypt(key: response.bacEnc.bytes, data: responseMutuaAuth) else {
                    observer.send(error: .invalidCommand)
                    return
                }
                let kMrtd = decResp.suffix(16)
                let kSeed = response.kIs ^ kMrtd

                let kSessMac = (kSeed + [0x00, 0x00, 0x00, 0x02]).sha1.prefix(16).bytes
                let kSessEnc = (kSeed + [0x00, 0x00, 0x00, 0x01]).sha1.prefix(16).bytes

                let seq = decResp[4..<8].bytes + decResp[12..<16].bytes
            
                
                let result = SessionKeys(kSessMac: kSessMac, kSessEnc: kSessEnc, seq: seq)

                observer.send(value: (tag, result))
                observer.sendCompleted()
                
            }
            
        }
    }
    
}
