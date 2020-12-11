//
//  NFCSession.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import CoreNFC
import ReactiveSwift

@available(iOS 13.0, *)
protocol NFCSessionDelegate: class {
    
    func session(didBecomeActive session: NFCTagReaderSession)
    func session(didFailedWith error: NFCError)
    func session(didFoundTag tag: NFCTag, passportTag: NFCISO7816Tag)
    
}

@available(iOS 13.0, *)
class NFCSession: NSObject {
    
    /// session that needs to be recreated every time
    private var session: NFCTagReaderSession?
    
    weak var delegate: NFCSessionDelegate?
    
    /// the message to display the progress
    var message: String? {
        didSet {
            guard let message = message else { return }
            session?.alertMessage = message
        }
    }
    
    func start() {
        
        guard let session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self) else {
            delegate?.session(didFailedWith: .connectionError)
            return
        }
        
        session.alertMessage = "Bring the top of your smartphone close to your document and wait a few seconds."
        
        self.session = session
        
        session.begin()
        
    }
    
    func finish() {
        
        session?.invalidate()
        session = nil
        
    }
    
    func connectProducer(to tag: NFCTag, passportTag: NFCISO7816Tag) -> SignalProducer<NFCISO7816Tag, NFCError> {
        
        return SignalProducer { [weak self] observer, lifetime in
            
            self?.session?.connect(to: tag) { (error) in
                if let _ = error {
                    self?.session?.invalidate()
                    observer.send(error: .connectionError)
                } else {
                    observer.send(value: passportTag)
                    observer.sendCompleted()
                }
            }
        }
        
    }
    
}

@available(iOS 13.0, *)
extension NFCSession: NFCTagReaderSessionDelegate {
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        delegate?.session(didBecomeActive: session)
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
       
        guard let error = error as? NFCReaderError else {
            delegate?.session(didFailedWith: .connectionError)
            finish()
            return
        }
        
        switch error.code {
        case .readerSessionInvalidationErrorUserCanceled:
            break
        default:
            finish()
            delegate?.session(didFailedWith: .connectionError)
        }
        
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {

        guard let firstTag = tags.first else { return }

        switch firstTag {
        case .iso7816(let tag):
            delegate?.session(didFoundTag: firstTag, passportTag: tag)
        default:
            session.invalidate()
            delegate?.session(didFailedWith: .invalidTag)
            break
        }

    }
    
}
