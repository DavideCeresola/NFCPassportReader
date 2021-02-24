//
//  NFCMutualAuthCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

@available(iOS 14.0, *)
class NFCMutualAuthCommand: NFCCommand {
    
    func performCommand(context: NFCCommandContext, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void) {
        
        guard case .bacResult(let response) = context.parameter else {
            completion(.failure(.invalidCommand))
            return
        }
        
        
        guard let apduChallenge = NFCISO7816APDU(data: response.apduMutua) else {
            completion(.failure(.invalidCommand))
            return
        }
        
        context.tag.sendCommand(apdu: apduChallenge) { (data, word1, word2, error) in
            
            let responseCode = String(format: "%02x%02x", word1, word2)
            guard responseCode == "9000" else {
                completion(.failure(.invalidCommand))
                return
            }
            
            let responseMutuaAuth = data.prefix(32)
            let kIsMacPad = Algorithms.getIsoPad(data: responseMutuaAuth)!
            let kIsMac = Algorithms.macEnc(masterKey: response.bacMac, data: kIsMacPad)
            let kIsMac2 = data.suffix(8)
            
            guard kIsMac == kIsMac2 else {
                completion(.failure(.invalidCommand))
                return
            }
            
            guard let decResp = Algorithms.tripleDesDecrypt(key: response.bacEnc.bytes, data: responseMutuaAuth) else {
                completion(.failure(.invalidCommand))
                return
            }
            let kMrtd = decResp.suffix(16)
            let kSeed = response.kIs ^ kMrtd
            
            let kSessMac = (kSeed + [0x00, 0x00, 0x00, 0x02]).sha1.prefix(16).bytes
            let kSessEnc = (kSeed + [0x00, 0x00, 0x00, 0x01]).sha1.prefix(16).bytes
            
            let seq = decResp[4..<8].bytes + decResp[12..<16].bytes
            
            
            let result = SessionKeys(kSessMac: kSessMac, kSessEnc: kSessEnc, seq: seq)
            
            completion(.success(.init(tag: context.tag, sessionKey: result)))
        }
    }
}
