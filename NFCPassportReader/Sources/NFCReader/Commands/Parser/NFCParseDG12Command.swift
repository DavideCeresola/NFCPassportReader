//
//  NFCParseDG12Command.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 18/04/23.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

@available(iOS 14.0, *)
class NFCParseDG12Command: NFCCommand {
    
    private let nfcData: NFCData
    
    init(nfcData: NFCData) {
        self.nfcData = nfcData
    }
    
    func performCommand(context: NFCCommandContext, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void) {
        
        guard case .data(let data) = context.parameter else {
            completion(.failure(.invalidCommand))
            return
        }
        
        guard let dg = try? DataGroup12(data.bytes) else {
            completion(.failure(.invalidCommand))
            return
        }
        
        self.nfcData.from(dg12: dg) { (result) in
            switch result {
            case .success(let nfcData):
                completion(.success(.init(tag: context.tag, sessionKey: context.sessionKey, parameter: .nfcData(nfcData))))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
