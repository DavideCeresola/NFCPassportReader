//
//  AlphaISOConverter.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 23/11/23.
//

import Foundation

class AlphaISOConverter {
    
    static func isoAlpha2(from isoAlpha3: String?) -> String? {
        guard let isoAlpha3 else { return nil }
        guard let jsonUrl = ModuleBundle.url(forResource: "CountryAlphaList", withExtension: "json") else { return nil }
        guard let jsonData = try? Data(contentsOf: jsonUrl) else { return nil }
        guard let alphaList = try? JSONDecoder().decode([CountryAlphaISO].self, from: jsonData) else { return nil }
        return alphaList
            .lazy
            .first(where: { $0.alpha3Country.caseInsensitiveCompare(isoAlpha3) == .orderedSame })?
            .alpha2Country
    }
    
}
