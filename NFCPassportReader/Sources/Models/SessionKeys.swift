//
//  SessionKeys.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation

struct SessionKeys {
    
    let kSessMac: [UInt8]
    let kSessEnc: [UInt8]
    let seq: [UInt8]
    
    func with(newSeq: [UInt8]) -> SessionKeys {
        return .init(kSessMac: kSessMac, kSessEnc: kSessEnc, seq: newSeq)
    }
    
}
