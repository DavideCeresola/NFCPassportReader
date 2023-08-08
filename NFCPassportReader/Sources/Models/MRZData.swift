//
//  MRZData.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 09/12/2020.
//

import Foundation

public struct MRZData: Equatable {
    
    /// date of birth
    public let birthDate: String?
    
    /// document expiration date
    public let expirationDate: String?
    
    /// document numner
    public let documentNumber: String
    
    /// type
    public let mrzType: MRZType
    
    /// nationality
    let nationality: String
    
    /// nationality ISO
    public var nationalityISO: String? {
        return Locale.init(identifier: nationality).identifier.uppercased()
    }
    
}
