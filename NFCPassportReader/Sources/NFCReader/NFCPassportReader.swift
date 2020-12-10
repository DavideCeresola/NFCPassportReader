//
//  NFCPassportReader.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import CoreNFC
import ReactiveSwift

@available(iOS 14.0, *)
public protocol NFCPassportReaderDelegate: class {
    
    func reader(didBecomeActive session: NFCTagReaderSession)
    func reader(didFailedWith error: NFCError)
    
}

@available(iOS 14.0, *)
public class NFCPassportReader {
    
    private lazy var session: NFCSession = .init()
    
    public weak var delegate: NFCPassportReaderDelegate?
    
    private let mrzData: MRZData
    
    init(mrzData: MRZData) {
        
        self.mrzData = mrzData
        session.delegate = self
        
    }
    
    private func performFlow(tag: NFCTag, passportTag: NFCISO7816Tag) {
        
        let connectionProducer = session.connectProducer(to: tag, passportTag: passportTag)
        let mrz = mrzData
        
        let x = connectionProducer
            .flatMap(.latest, NFCSelectCommand.performCommand(tag:))
            .map { ($0, mrz) }
            .flatMap(.latest, { NFCBacAuthCommand.performCommand(tag: $0, mrzData: $1) })
            .flatMap(.latest, { NFCMutualAuthCommand.performCommand(tag: $0.0, response: $0.1) })
        
        
    }
    
}

@available(iOS 14.0, *)
extension NFCPassportReader: NFCSessionDelegate {
    
    func session(didBecomeActive session: NFCTagReaderSession) {
        delegate?.reader(didBecomeActive: session)
    }
    
    func session(didFailedWith error: NFCError) {
        delegate?.reader(didFailedWith: error)
    }
    
    func session(didFoundTag tag: NFCTag, passportTag: NFCISO7816Tag) {
        performFlow(tag: tag, passportTag: passportTag)
    }
    
    
}
