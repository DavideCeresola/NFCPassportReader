//
//  MRZData.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 09/12/2020.
//

import Foundation

public struct MRZData: Equatable {
    
    /// the raw mrz
    public let mrz: String
    
    /// date of birth
    public let birthDate: String
    
    /// document expiration date
    public let expirationDate: String
    
    /// document numner
    public let documentNumber: String
    
    public static func ==(lhs: MRZData, rhs: MRZData) -> Bool {
        return rhs.mrz == lhs.mrz
    }
    
}
