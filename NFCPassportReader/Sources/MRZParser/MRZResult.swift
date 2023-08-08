//
//  MRZResult.swift
//  MRZParser
//
//  Created by Davide Ceresola on 14/10/2018.
//

import Foundation

// MARK: - MRZResult
public enum MRZResult {
    /// Any `TD1, TD2, TD3 or MRV-A, MRV-B` supported document (e.g. passport, visa, id).
    case genericDocument(GenericDocument)
    
}

// MARK: - GenericDocument
extension MRZResult {
    public struct GenericDocument {
        public let mrzType: MRZType
        public let documentType: String
        public let countryCode: String
        public let surnames: String
        public let givenNames: String
        public let documentNumber: String
        public let nationalityCountryCode: String
        public let birthdate: Date? // `nil` if formatting failed
        public let sex: String? // `nil` if formatting failed
        public let expiryDate: Date? // `nil` if formatting failed
        public let personalNumber: String
        public let personalNumber2: String? // `nil` if not provided
        public let isDocumentNumberValid: Bool
        public let isBirthdateValid: Bool
        public let isExpiryDateValid: Bool
        public let isPersonalNumberValid: Bool?
        public let allCheckDigitsValid: Bool
    }
}

extension MRZResult.GenericDocument {
    
    private static let dateFormatter: DateFormatter = {
        let dateStringFormatter = DateFormatter()
        dateStringFormatter.dateFormat = "YYMMdd"
        dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateStringFormatter.timeZone = TimeZone(abbreviation: "GMT+0:00")
        return dateStringFormatter
    }()
    
    public var mrzData: MRZData? {
        
        return .init(birthDate: birthdate != nil ? MRZResult.GenericDocument.dateFormatter.string(from: birthdate!) : nil,
                     expirationDate: expiryDate != nil ? MRZResult.GenericDocument.dateFormatter.string(from: expiryDate!) : nil,
                     documentNumber: documentNumber,
                     mrzType: mrzType,
                     nationality: countryCode)
       
    }
    
}
