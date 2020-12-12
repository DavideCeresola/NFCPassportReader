//
//  NFCData.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import UIKit
import CoreLocation

@available(iOS 13, *)
public struct NFCData {
    
    public struct Address {
        
    }
    
    public private(set) var name : String?
    public private(set) var surname : String?
    public private(set) var personalNumber : String?
    public private(set) var dateOfBirth : Date?
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
    public private(set) var rawAddress : String?
    
    func from(dg11 datagroup: DataGroup11, completion: ((Result<NFCData, NFCError>) -> Void)? = nil) {
        
        var newData = NFCData(name: parseName(datagroup.fullName),
                       surname: parseSurname(datagroup.fullName),
                       personalNumber: datagroup.personalNumber,
                       dateOfBirth: parseDate(datagroup.dateOfBirth),
                       cityOfBirth: parseCityOfBirth(datagroup.placeOfBirth),
                       provinceOfBirth: parseProvinceOfBirth(datagroup.placeOfBirth),
                       telephone: datagroup.telephone,
                       profession: datagroup.profession,
                       title: datagroup.title,
                       personalSummary: datagroup.personalSummary,
                       proofOfCitizenship: datagroup.proofOfCitizenship,
                       tdNumbers: datagroup.tdNumbers,
                       custodyInfo: datagroup.custodyInfo,
                       image: self.image,
                       data: self.data,
                       rawAddress: datagroup.address)
        
        parseResidenceAddress(datagroup.address) { (result) in
            switch result {
            case .success(let address):
                newData.residenceAddress = address
                completion?(.success(newData))
            case .failure(let error):
                completion?(.failure(error))
            }
        }
        
    }
    
    func from(dg2 datagroup: DataGroup2, completion: ((Result<NFCData, NFCError>) -> Void)? = nil) {
        
        let newData = NFCData(name: self.name,
                       surname: self.surname,
                       personalNumber: self.personalNumber,
                       dateOfBirth: self.dateOfBirth,
                       cityOfBirth: self.cityOfBirth,
                       provinceOfBirth: self.provinceOfBirth,
                       residenceAddress: self.residenceAddress,
                       telephone: self.telephone,
                       profession: self.profession,
                       title: self.title,
                       personalSummary: self.personalSummary,
                       proofOfCitizenship: self.proofOfCitizenship,
                       tdNumbers: self.tdNumbers,
                       custodyInfo: self.custodyInfo,
                       image: datagroup.getImage(),
                       data: self.data,
                       rawAddress: self.rawAddress)
        
        completion?(.success(newData))
        
    }
    
    func from(dg1 datagroup: DataGroup1, completion: ((Result<NFCData, NFCError>) -> Void)? = nil) {
        
        let newData = NFCData(name: self.name,
                       surname: self.surname,
                       personalNumber: self.personalNumber,
                       dateOfBirth: self.dateOfBirth,
                       cityOfBirth: self.cityOfBirth,
                       provinceOfBirth: self.provinceOfBirth,
                       residenceAddress: self.residenceAddress,
                       telephone: self.telephone,
                       profession: self.profession,
                       title: self.title,
                       personalSummary: self.personalSummary,
                       proofOfCitizenship: self.proofOfCitizenship,
                       tdNumbers: self.tdNumbers,
                       custodyInfo: self.custodyInfo,
                       image: self.image,
                       data: datagroup.elements,
                       rawAddress: self.rawAddress)
        
        completion?(.success(newData))
        
    }
    
}

// MARK: - Internal Parsers
@available(iOS 13, *)
private extension NFCData {
    
    func parseName(_ fullName: String?) -> String? {
        
        guard let fullName = fullName else {
            return nil
        }
        
        let rawName = fullName.components(separatedBy: "<<").last
        let splittedName = rawName?.split(separator: "<")
        return splittedName?.joined(separator: " ").capitalized
        
    }
    
    private func parseSurname(_ fullName: String?) -> String? {
        
        guard let fullName = fullName else {
            return nil
        }
        
        return fullName.components(separatedBy: "<<").first?.capitalized
        
    }
    
    private func parseDate(_ date: String?) -> Date? {
        
        guard let rawDate = date else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        
        return formatter.date(from: rawDate)
        
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
        
        guard let residenceComponents = rawResidence?.replacingOccurrences(of: "<", with: " ") else {
            completion?(.failure(.invalidCommand))
            return
        }
    
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(residenceComponents) { (placemarks, error) in
            guard let placemark = placemarks?.first, error == nil else {
                completion?(.failure(.invalidCommand))
                return
            }
            
            print("Placemark:", placemark)
            completion?(.success(Address()))
            
        }
        
    }
    
}
