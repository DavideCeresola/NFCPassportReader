//
//  NFCError.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation

public enum NFCError: Error {
    
    /// used when an user tap on cancel
    case cancelled
    
    /// used when an user approach the device to a unrecognized tag
    case invalidTag
    
    /// used when the session raised an error
    case connectionError
    
    /// used when there is an error through the reading flow
    case invalidCommand
    
}
