//
//  NFCParseDG1Command.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 15/12/2020.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

@available(iOS 14.0, *)
class NFCParseDG1Command: NFCCommand {
    
    private let nfcData: NFCData
    
    init(nfcData: NFCData) {
        self.nfcData = nfcData
    }
    
    func performCommand(context: NFCCommandContext, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void) {

        guard case .data(let data) = context.parameter else {
            completion(.failure(.invalidCommand))
            return
        }
        
        guard let dg = try? DataGroup1(data.bytes) else {
            completion(.failure(.invalidCommand))
            return
        }
        
        self.nfcData.from(dg1: dg) { (result) in
            switch result {
            case .success(let nfcData):
                completion(.success(.init(tag: context.tag, sessionKey: context.sessionKey, parameter: .nfcData(nfcData))))
            case .failure:
                completion(.failure(.invalidCommand))
            }
        }
        
    }    
}
