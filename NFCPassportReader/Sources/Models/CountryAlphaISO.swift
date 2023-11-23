//
//  CountryAlphaISO.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 23/11/23.
//

import Foundation

struct CountryAlphaISO: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case name
        case alpha3Country = "alpha-3"
        case alpha2Country = "alpha-2"
    }
    
    let name: String
    let alpha3Country: String
    let alpha2Country: String
}
