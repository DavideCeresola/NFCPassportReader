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
    func applyDocumentNumberCorrection(documentNumber: MRZField,
                                       checkDigitValidation: (MRZField) -> Bool,
                                       using formatter: MRZFieldFormatter) -> MRZField?
}

extension Parser {
    func applyDocumentNumberCorrection(documentNumber: MRZField,
                                       checkDigitValidation: (MRZField) -> Bool,
                                       using formatter: MRZFieldFormatter) -> MRZField? {
        
        guard !documentNumber.isValid! else { return nil }
        
        let documentNumberVariances = formatter.variantsWithCheckDigit(for: documentNumber)
        
        return documentNumberVariances.first(where: { checkDigitValidation($0) })
        
    }
}
