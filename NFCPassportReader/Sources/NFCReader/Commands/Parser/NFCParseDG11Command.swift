//
//  NFCParseDG11Command.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 12/12/2020.
//

import Foundation
import CoreNFC
import ReactiveSwift

@available(iOS 14.0, *)
class NFCParseDG11Command: NFCCommand {
    
    private let nfcData: NFCData
    
    init(nfcData: NFCData) {
        self.nfcData = nfcData
    }
    
    func performCommand(tag: NFCISO7816Tag, sessionKeys: SessionKeys?, param: Any?) -> SignalProducer<(NFCISO7816Tag, SessionKeys?, Any?), NFCError> {
    
        guard let data = param as? Data else {
            return .init(error: .invalidCommand)
        }
        
        return SignalProducer { [weak self] observer, lifetime in
            
            guard let dg = try? DataGroup11(data.bytes) else {
                observer.send(error: .invalidCommand)
                return
            }
            
            self?.nfcData.from(dg11: dg) { (result) in
                switch result {
                case .success(let newData):
                    observer.send(value: (tag, sessionKeys, newData))
                    observer.sendCompleted()
                case .failure(let error):
                    observer.send(error: error)
                }
            }
            
        }
        
    }
    
}
