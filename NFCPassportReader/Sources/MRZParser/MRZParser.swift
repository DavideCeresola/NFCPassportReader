//
//  MRZParser.swift
//  MRZParser
//
//  Created by Davide Ceresola on 14/10/2018.
//

import Foundation

public final class MRZParser {
    private let formatter: MRZFieldFormatter

    public init(ocrCorrection: Bool = false) {
        formatter = MRZFieldFormatter(ocrCorrection: ocrCorrection)
    }

    public func parse(mrzLines: [String]) -> MRZResult? {
        let parser = Parsers.parser(for: mrzLines)
        return parser?.parse(mrzLines: mrzLines, using: formatter)
    }
    
    public func parse(mrzString: String) -> MRZResult? {
        return parse(mrzLines: mrzString.components(separatedBy: "\n"))
    }
}
