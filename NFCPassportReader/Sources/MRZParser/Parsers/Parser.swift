//
//  Parser.swift
//  QKMRZParser
//
//  Created by Davide Ceresola on 24/08/2022.
//

import Foundation

protocol Parser {
    static var shared: Self { get }
    func parse(mrzLines: [String], using formatter: MRZFieldFormatter) -> MRZResult
    func correctDocumentNumber(documentNumber: MRZField,
                               birthdate: MRZField,
                               expiryDate: MRZField,
                               optionalData: MRZField?,
                               finalCheckDigit: MRZField?,
                               optionalData2: MRZField?,
                               personalNumber: MRZField?,
                               allCheckDigitsValid: Bool,
                               using formatter: MRZFieldFormatter) -> (MRZField, Bool)
}
