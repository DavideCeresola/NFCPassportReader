//
//  NFCAuthCompositeCommand.swift
//  NFCPassportReader
//
//  Created by marco.incerti on 12/02/24.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif


@available(iOS 14.0, *)
class NFCAuthCompositeCommand: NFCCommand {

    private var mrzData: [MRZData]
    private var flowExecutor: CompositeFlowExecutor?
    
    init(mrzData: [MRZData]) {
        self.mrzData = mrzData
    }
    
    func performCommand(context: NFCCommandContext, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void) {
        
        guard !mrzData.isEmpty else {
            return completion(.failure(.invalidCommand))
        }
        
        let mrz = mrzData.removeFirst()
                
        let commands = buildCommands(with: mrz)
        
        flowExecutor = CompositeFlowExecutor(flow: commands)
        
        flowExecutor!.start(from: .success(context)) { [unowned self] result in
            switch result {
            case .success(let res):
                completion(.success(res))
            case .failure:
                performCommand(context: context, completion: completion)
            }
        }
        
    }
    
    private func buildCommands(with mrzData: MRZData) -> [NFCCommand] {
        [
            NFCBacAuthCommand(mrzData: mrzData),
            NFCMutualAuthCommand(),
        ]
    }
}

@available(iOS 14.0, *)
extension NFCAuthCompositeCommand {
    
    class CompositeFlowExecutor {
        
        var flow: [NFCCommand]
        
        private var currentCommand: NFCCommand?
        
        init(flow: [NFCCommand]) {
            self.flow = flow
        }
        
        func start(from contextResult: Result<NFCCommandContext, NFCError>, completion: @escaping (Result<NFCCommandContext, NFCError>) -> Void) {
            
            do {
                
                let context = try contextResult.get()
                if flow.isEmpty {
                    return completion(contextResult)
                }
                
                let command = flow.removeFirst()
                self.currentCommand = command
                
                command.performCommand(context: context) { [weak self] contextResult in
                    self?.start(from: contextResult, completion: completion)
                }
                
            } catch {
                completion(contextResult)
            }
        }
    }
}

