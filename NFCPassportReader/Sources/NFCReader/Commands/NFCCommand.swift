//
//  NFCCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 12/12/2020.
//

import Foundation
import CoreNFC

@available(iOS 14.0, *)
struct NFCCommandContext {
    
    enum Parameter {
        case empty
        case parseLenght(Int)
        case data(Data)
        case nfcData(NFCData)
        case bacResult(BacAuthResult)
    }
    
    var tag: NFCISO7816Tag
    var sessionKey: SessionKeys?
    var parameter: Parameter
    
    internal init(tag: NFCISO7816Tag, sessionKey: SessionKeys? = nil, parameter: NFCCommandContext.Parameter = .empty) {
        self.tag = tag
        self.sessionKey = sessionKey
        self.parameter = parameter
    }
}

@available(iOS 14.0, *)
protocol NFCCommand {

    func performCommand(context: NFCCommandContext, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void)
}
