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
    
    func reader(didFailedWith error: NFCError)
    func reader(didSuccededWith data: NFCData)
    
}

@available(iOS 14.0, *)
public class NFCPassportReader {
    
    private lazy var session: NFCSession = .init()
    
    public weak var delegate: NFCPassportReaderDelegate?
    
    private let mrzData: MRZData
    private let displayMessage: String?
    
    private lazy var disposable: SerialDisposable = .init()
    
    private lazy var nfcData: NFCData = .init(mrzType: mrzData.mrzType)
    
    /// the current flow to perform
    private lazy var flow: [NFCCommand] = [
        NFCSelectCommand(),
        NFCBacAuthCommand(mrzData: mrzData),
        NFCMutualAuthCommand(),
        NFCReadDGCommand(dataGroup: .dg2),
        NFCExtractDataCommand(),
        NFCParseDG2Command(nfcData: nfcData),
        NFCReadDGCommand(dataGroup: .dg11),
        NFCExtractDataCommand(),
        NFCParseDG11Command(nfcData: nfcData)
    ]
    
    public init(mrzData: MRZData, displayMessage: String? = nil) {
        
        self.mrzData = mrzData
        self.displayMessage = displayMessage
        session.delegate = self
        
    }
    
    public func start() {
        
        session.start()
        
    }
    
    private func performFlow(tag: NFCTag, passportTag: NFCISO7816Tag) {
        
        let progressBlock: ((Double) -> Void) = { [weak self] progress in
            self?.updateProgress(progress)
        }
        
        let stepsNumber = Double(flow.count)
        
        let connectProducer = session.connectProducer(to: tag, passportTag: passportTag)
            .map { tag -> (NFCISO7816Tag, SessionKeys?, Any?) in (tag, nil, nil) }
        
        let flowProducer = flow.enumerated().reduce(into: connectProducer) { (result, partial) in
            result = result.flatMap(.latest, partial.element.performCommand(tag:sessionKeys:param:))
                .progress(Double(partial.offset + 1) / stepsNumber, progressBlock: progressBlock)
        }
        
        disposable.inner = flowProducer
            .on(failed: { [weak self] error in
                self?.session.finish()
                self?.delegate?.reader(didFailedWith: error)
            })
            .on(value: { [weak self] value in
                guard let nfcData = value.2 as? NFCData else {
                    return
                }
                self?.delegate?.reader(didSuccededWith: nfcData)
            })
            .on(completed: { [weak self] in
                self?.session.finish()
            })
            .start()
        
    }
    
    private func updateProgress(_ progress: Double) {
        
        let percentage = Int(progress * 100.0)
        let message: String
        let percentageMessage = "\(percentage)%\nScan in progress"
        
        if progress < 0.5 {
            message = "😐 \(percentageMessage)"
        } else if progress < 0.75 {
            message = "🙂 \(percentageMessage)"
        } else if progress < 1 {
            message = "😃 \(percentageMessage)"
        } else {
            message = "🤩 \(percentageMessage)"
        }
        
        session.message = message
        
    }
    
}

@available(iOS 14.0, *)
extension NFCPassportReader: NFCSessionDelegate {
    
    func session(didBecomeActive session: NFCTagReaderSession) {
        self.session.message = displayMessage
    }
    
    func session(didFailedWith error: NFCError) {
        delegate?.reader(didFailedWith: error)
    }
    
    func session(didFoundTag tag: NFCTag, passportTag: NFCISO7816Tag) {
        performFlow(tag: tag, passportTag: passportTag)
    }
    
}
