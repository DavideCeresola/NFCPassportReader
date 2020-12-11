//
//  SignalProducer+Progress.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import ReactiveSwift

extension SignalProducer {
    
    func progress(_ progress: Double, progressBlock: ((Double) -> Void)? = nil) -> SignalProducer<Value, Error> {
        
        return self.on(completed: {
            progressBlock?(progress)
        })
    
    }
    
}
