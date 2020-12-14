//
//  NFCCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 12/12/2020.
//

import Foundation
import CoreNFC
import ReactiveSwift

@available(iOS 14.0, *)
protocol NFCCommand {
    
    func performCommand(tag: NFCISO7816Tag, sessionKeys: SessionKeys?, param: Any?)
    -> SignalProducer<(NFCISO7816Tag, SessionKeys?, Any?), NFCError>
    
}
