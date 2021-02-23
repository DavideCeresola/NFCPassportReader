//
//  NFCData.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import UIKit
import CoreLocation

@available(iOS 14.0, *)
public class NFCData {
    
    public struct Address {
        public let street: String
        public let streetNumber: String?
        public let postalCode: String
        public let city: String
        public let isoCountryCode: String
    }
    
    public private(set) var name : String?
    public private(set) var surname : String?
    public private(set) var personalNumber : String?
    public private(set) var cityOfBirth : String?
    public private(set) var provinceOfBirth : String?
    public private(set) var residenceAddress : Address?
    public private(set) var telephone : String?
    public private(set) var profession : String?
    public private(set) var title : String?
    public private(set) var personalSummary : String?
    public private(set) var proofOfCitizenship : String?
    public private(set) var tdNumbers : String?
    public private(set) var custodyInfo : String?
    public private(set) var image : UIImage?
    public private(set) var data : [String: String]?
    public let mrzType: MRZType
    private var rawDateOfBirth : String?
    private var rawAddress : String?
    
    public var dateOfBirth: Date? {
        
        guard let rawDate = rawDateOfBirth else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        return formatter.date(from: rawDate)
        
    }
    
    init(mrzType: MRZType) {
        self.mrzType = mrzType
    }
    
    func from(dg11 datagroup: DataGroup11, completion: ((Result<NFCData, NFCError>) -> Void)? = nil) {
        
        name = parseName(datagroup.fullName)
        surname = parseSurname(datagroup.fullName)
        personalNumber = datagroup.personalNumber
        rawDateOfBirth = datagroup.dateOfBirth
        cityOfBirth = parseCityOfBirth(datagroup.placeOfBirth)
        provinceOfBirth = parseProvinceOfBirth(datagroup.placeOfBirth)
        telephone = datagroup.telephone
        profession = datagroup.profession
        title = datagroup.title
        personalSummary = datagroup.personalSummary
        proofOfCitizenship = datagroup.proofOfCitizenship
        tdNumbers = datagroup.tdNumbers
        custodyInfo = datagroup.custodyInfo
        rawAddress = datagroup.address
        
        parseResidenceAddress(datagroup.address) { [weak self] (result) in
            
            guard let self = self else {
                completion?(.failure(.invalidCommand))
                return
            }
            
            switch result {
            case .success(let address):
                self.residenceAddress = address
                completion?(.success(self))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
        
    }
    
    func from(dg2 datagroup: DataGroup2, completion: ((Result<NFCData, NFCError>) -> Void)? = nil) {
        
        self.image = datagroup.getImage()
        completion?(.success(self))
        
    }
    
    func from(dg1 datagroup: DataGroup1, completion: ((Result<NFCData, NFCError>) -> Void)? = nil) {
        
        let nameComponents = datagroup.elements["5B"]
        let dateComponents = datagroup.elements["5F57"]
        
        name = parseName(nameComponents)
        surname = parseSurname(nameComponents)
        rawDateOfBirth = dateComponents
        
        completion?(.success(self))
        
    }
    
}

// MARK: - Internal Parsers
@available(iOS 14.0, *)
private extension NFCData {
    
    func parseName(_ fullName: String?) -> String? {
        
        guard let fullName = fullName else {
            return nil
        }
        
        let rawName = fullName.components(separatedBy: "<<")
        
        guard rawName.count > 1 else {
            return nil
        }
        
        let splittedName = rawName[1].split(separator: "<")
        return splittedName.joined(separator: " ").capitalized
        
    }
    
    private func parseSurname(_ fullName: String?) -> String? {
        
        guard let fullName = fullName else {
            return nil
        }
        
        return fullName.components(separatedBy: "<<").first?.capitalized
        
    }
    
    private func parseCityOfBirth(_ placeOfBirth: String?) -> String? {
        
        guard let city = placeOfBirth?.split(separator: "<").first else {
            return nil
        }
        
        return String(city)
        
    }
    
    private func parseProvinceOfBirth(_ placeOfBirth: String?) -> String? {
        
        guard let province = placeOfBirth?.split(separator: "<").last else {
            return nil
        }
        
        return String(province)
        
    }
    
    private func parseResidenceAddress(_ rawResidence: String?,
                                       completion: ((Result<Address, NFCError>) -> Void)? = nil) {
        
        guard let residenceComponents = rawResidence?.components(separatedBy: "<"), residenceComponents.count > 1 else {
            completion?(.failure(.invalidAddress))
            return
        }
        
        let validComponents = residenceComponents.prefix(2).joined(separator: " ")
    
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(validComponents) { (placemarks, error) in
            guard let placemark = placemarks?.first, error == nil else {
                completion?(.failure(.invalidAddress))
                return
            }
            
            let streetNumber = placemark.subThoroughfare
            
            guard let street = placemark.thoroughfare,
                  let postalCode = placemark.postalCode,
                  let city = placemark.locality,
                  let isoCountryCode = placemark.isoCountryCode else {
                completion?(.failure(.invalidAddress))
                return
            }
            
            completion?(.success(Address(street: street,
                                         streetNumber: streetNumber,
                                         postalCode: postalCode,
                                         city: city,
                                         isoCountryCode: isoCountryCode)))
            
        }
        
    }
    
}
