//
//  NFCPassportReader.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation

#if canImport(CoreNFC)
import CoreNFC
#endif

@available(iOS 14.0, *)
public protocol NFCPassportReaderDelegate: AnyObject {
    
    func reader(didFailedWith error: NFCError)
    func reader(didSuccededWith data: NFCData)
    
    func readerMessage(for progress: Double) -> String?
    func readerFailedMessage() -> String?
}

@available(iOS 14.0, *)
public class NFCPassportReader {
    
    private lazy var session: NFCSession = .init()
    
    public weak var delegate: NFCPassportReaderDelegate?
    
    private let mrzData: MRZData
    private let displayMessage: String?
    private var flowExecutor: FlowExecutor?
    
    private lazy var nfcData: NFCData = .init(mrzType: mrzData.mrzType)
    
    private var nfcFlow: [NFCCommand] {
        
        if mrzData.mrzType == .td1 {
            return td1Flow
        }
        return td3Flow
    }
    
    /// the current flow to perform
    private var td1Flow: [NFCCommand] {
        [
            NFCSelectCommand(),
            NFCBacAuthCommand(mrzData: mrzData),
            NFCMutualAuthCommand(),
            
            NFCReadDGCommand(dataGroup: .dg1),
            NFCExtractDataCommand(),
            NFCParseDG1Command(nfcData: nfcData),
            
            NFCReadDGCommand(dataGroup: .dg11),
            NFCExtractDataCommand(),
            NFCParseDG11Command(nfcData: nfcData),
            
            NFCReadDGCommand(dataGroup: .dg12),
            NFCExtractDataCommand(),
            NFCParseDG12Command(nfcData: nfcData),
        ]
    }
    
    /// the passport flow to perform
    private var td3Flow: [NFCCommand] {
        [
            NFCSelectCommand(),
            NFCBacAuthCommand(mrzData: mrzData),
            NFCMutualAuthCommand(),
            
            NFCReadDGCommand(dataGroup: .dg1),
            NFCExtractDataCommand(),
            NFCParseDG1Command(nfcData: nfcData),
            
            NFCReadDGCommand(dataGroup: .dg12),
            NFCExtractDataCommand(),
            NFCParseDG12Command(nfcData: nfcData)
        ]
    }
    
    public init(mrzData: MRZData, displayMessage: String? = nil) {
        
        self.mrzData = mrzData
        self.displayMessage = displayMessage
        session.delegate = self
        
    }
    
    public func start(with message: String? = nil) {
        
        session.start(with: message)
    }
    
    private func performFlow(tag: NFCTag, passportTag: NFCISO7816Tag) {
        
        let session = self.session
        let delegate = self.delegate
        
        self.flowExecutor = nil
        
        let flowExecutor = FlowExecutor(session: session, flow: nfcFlow)
        flowExecutor.progressBlock = { session.message = delegate?.readerMessage(for: $0) }
        flowExecutor.start(with: tag, passportTag: passportTag) { result in
            
            switch result {
            
            case .failure(let error):
                session.finish(errorMessage: delegate?.readerFailedMessage())
                delegate?.reader(didFailedWith: error)
                
            case .success(let context):
                guard case .nfcData(let nfcData) = context.parameter else { return }
                session.finish()
                delegate?.reader(didSuccededWith: nfcData)
            }
        }
        self.flowExecutor = flowExecutor
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

@available(iOS 14.0, *)
class FlowExecutor {
    
    let session: NFCSession
    
    var flow: [NFCCommand]
    var initialStepsCount: Int
    
    var progressBlock: ((Double) -> Void)?
    private var currentCommand: NFCCommand?
    
    init(session: NFCSession, flow: [NFCCommand]) {
        self.session = session
        self.flow = flow
        self.initialStepsCount = flow.count
    }
        
    func start(with tag: NFCTag, passportTag: NFCISO7816Tag, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void) {
        
        session.performConnection(to: tag, passportTag: passportTag) { [weak self] result in
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let tag):
                let context = NFCCommandContext(tag: tag)
                self?.executeNext(from: .success(context), completion: completion)
            }
        }
    }
    
    private func executeNext(from contextResult: Result<NFCCommandContext, NFCError>, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void) {
        
        do {
            
            let context = try contextResult.get()
            if flow.isEmpty {
                completion(contextResult)
                return
            }
            
            let command = flow.removeFirst()
            self.currentCommand = command
            updateProgress(with: flow.count)
            command.performCommand(context: context) { [weak self] contextResult in
                self?.executeNext(from: contextResult, completion: completion)
            }
            
        } catch {
            completion(contextResult)
        }
    }
    
    private func updateProgress(with remainingSteps: Int) {

        let progress = 1.0 - Double(remainingSteps) / Double(initialStepsCount)
        progressBlock?(progress)
    }
}
