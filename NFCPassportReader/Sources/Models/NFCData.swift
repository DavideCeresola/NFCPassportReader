//
//  NFCData.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import UIKit

@available(iOS 13, *)
public struct NFCData {
    
    public private(set) var fullName : String?
    public private(set) var personalNumber : String?
    public private(set) var dateOfBirth : String?
    public private(set) var placeOfBirth : String?
    public private(set) var address : String?
    public private(set) var telephone : String?
    public private(set) var profession : String?
    public private(set) var title : String?
    public private(set) var personalSummary : String?
    public private(set) var proofOfCitizenship : String?
    public private(set) var tdNumbers : String?
    public private(set) var custodyInfo : String?
    public private(set) var imageData : UIImage?
    
    func from(dg11 datagroup: DataGroup11) -> NFCData {
        
        return NFCData(fullName: datagroup.fullName,
                       personalNumber: datagroup.personalNumber,
                       dateOfBirth: datagroup.dateOfBirth,
                       placeOfBirth: datagroup.placeOfBirth,
                       address: datagroup.address,
                       telephone: datagroup.telephone,
                       profession: datagroup.profession,
                       title: datagroup.title,
                       personalSummary: datagroup.personalSummary,
                       proofOfCitizenship: datagroup.proofOfCitizenship,
                       tdNumbers: datagroup.tdNumbers,
                       custodyInfo: datagroup.custodyInfo,
                       imageData: self.imageData)
        
    }
    
    func from(dg2 datagroup: DataGroup2) -> NFCData {
        
        return NFCData(fullName: self.fullName,
                       personalNumber: self.personalNumber,
                       dateOfBirth: self.dateOfBirth,
                       placeOfBirth: self.placeOfBirth,
                       address: self.address,
                       telephone: self.telephone,
                       profession: self.profession,
                       title: self.title,
                       personalSummary: self.personalSummary,
                       proofOfCitizenship: self.proofOfCitizenship,
                       tdNumbers: self.tdNumbers,
                       custodyInfo: self.custodyInfo,
                       imageData: datagroup.getImage())
        
    }
    
}
