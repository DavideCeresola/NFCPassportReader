//
//  Algorithms.swift
//  NFCPassportReader
//
//  Created by Davide Ceresola on 10/12/2020.
//

import Foundation
import IDZSwiftCommonCrypto

class Algorithms {
    
    static func tripleDesEncrypt(key: [UInt8], data: Data) -> Data? {
        let algorithm = Cryptor.Algorithm.tripleDES
        let iv: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        var masterKey: [UInt8]
        if key.count == 8 {
            masterKey = key + key + key
        } else if key.count == 16 {
            masterKey = key + key.prefix(8)
        } else {
            masterKey = key.prefix(24) + []
        }
        
        let cyphor = Cryptor.init(operation: .encrypt, algorithm: algorithm, mode: .CBC, padding: .NoPadding, key: masterKey, iv: iv)
        guard let cipherText = cyphor.update(data)?.final() else {
            return nil
        }
        
        return Data(cipherText)
    }
    
    static func tripleDesDecrypt(key: [UInt8], data: Data) -> Data? {
        let algorithm = Cryptor.Algorithm.tripleDES
        let iv: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        var masterKey: [UInt8]
        if key.count == 8 {
            masterKey = key + key + key
        } else if key.count == 16 {
            masterKey = key + key.prefix(8)
        } else {
            masterKey = key.prefix(24) + []
        }
        
        let cyphor = Cryptor.init(operation: .decrypt, algorithm: algorithm, mode: .CBC, padding: .NoPadding, key: masterKey, iv: iv)
        guard let cipherText = cyphor.update(data)?.final() else {
            return nil
        }
        
        return Data(cipherText)
    }
    
    static func macEnc(masterKey: Data, data: Data) -> Data? {
        
        let k1 = masterKey.prefix(8)
        
        let k2Range = masterKey.count >= 16 ? 8..<16 : 0..<8
        let k2 = masterKey[k2Range]
        
        let k3Range = masterKey.count >= 24 ? 16..<24 : 0..<8
        let k3 = masterKey[k3Range]
        
        let mid1 = tripleDesEncrypt(key: k1.bytes, data: data)!
        let mid2 = tripleDesDecrypt(key: k2.bytes, data: mid1.suffix(8))!
        let mid3 = tripleDesEncrypt(key: k3.bytes, data: mid2.prefix(8))!
        
        return mid3
    }
    
    static func getIsoPad(data: Data) -> Data? {
        var padLen: Int = 0
        
        if (data.count & 0x7) == 0 {
            padLen = data.count + 8
        } else {
            padLen = data.count - (data.count & 0x7) + 0x08
        }
        
        var padData = Data(count: padLen).bytes
        for i in 0..<data.bytes.count {
            let byte = data[i]
            padData[i] = byte
        }
        padData[data.count] = 0x80
        for i in (data.count + 1)..<padData.count {
            padData[i] = 0x00
        }
        return Data(padData)
        
    }
    
    static func isoRemove(data: Data) -> Data? {
        
        var x = data.count - 1
        for i in (0..<data.count).reversed() {
            if data[i] == 0x80 {
                break
            }
            if data[i] != 0x00 {
                fatalError("padding not found")
            }
            x -= 1
        }
        return data.prefix(x)
        
    }
    
}
