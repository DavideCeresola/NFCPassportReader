//
//  NFCSelectCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import CoreNFC
import ReactiveSwift

@available(iOS 14.0, *)
class NFCSelectCommand {
    
    private static let selectCommand = "00A4040C07A0000002471001".hexaData
    
    static func performCommand(tag: NFCISO7816Tag) -> SignalProducer<NFCISO7816Tag, NFCError> {
        
        return SignalProducer { observer, lifetime in
            guard let apdu = NFCISO7816APDU(data: NFCSelectCommand.selectCommand) else {
                observer.send(error: .invalidCommand)
                return
            }
            tag.sendCommand(apdu: apdu) { (result) in
                switch result {
                case .success(let response) where response.statusWord1 == 144:
                    observer.send(value: tag)
                    observer.sendCompleted()
               default:
                    observer.send(error: .invalidCommand)
                }
            }
        }
        
    }
}
