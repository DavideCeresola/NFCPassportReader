//
//  NFCSelectCommand.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import CoreNFC

@available(iOS 14.0, *)
class NFCSelectCommand: NFCCommand {
    
    private static let selectCommand = "00A4040C07A0000002471001".hexaData
    
    func performCommand(context: NFCCommandContext, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void) {

        guard let apdu = NFCISO7816APDU(data: NFCSelectCommand.selectCommand) else {
            completion(.failure(.invalidCommand))
            return
        }
        context.tag.sendCommand(apdu: apdu) { (result) in
            switch result {
            case .success(let response) where response.statusWord1 == 144:
                completion(.success(.init(tag: context.tag)))
            default:
                completion(.failure(.invalidCommand))
            }
        }
    }
}
