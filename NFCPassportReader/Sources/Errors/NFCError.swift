//
//  NFCError.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation

public enum NFCError: Error {
    
    case cannotOpenSession
    case invalidated
    case invalidTag
    case cannotConnectToTag
    case invalidCommand
    
}
