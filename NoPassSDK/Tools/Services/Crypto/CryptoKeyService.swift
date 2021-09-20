//
//  CryptoKeyService.swift
//  Mapd
//
//  Created by Влад on 9/30/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

enum CryptoKeyService {
    
    static func generateRSAKeyPair(sizeInBits: Int = 2048) -> (privateKey: PrivateKey, publicKey: PublicKey)? {
        do {
            return try SwiftyRSA.generateRSAKeyPair(sizeInBits: sizeInBits)
        } catch {
            return nil
        }
    }
    
    
    
    static func getEncodedPublicKey(publicKey: PublicKey) -> String? {
        if let (modulus, exponent) = CryptoKeyService.getModAndExpFrom(publicKey: publicKey.reference) {

            guard let modulusDec = modulus.hexDescription.hexToDecial(), let exponentDec = exponent.hexDescription.hexToDecial() else {
                return nil
            }

            let dict = ["modulus": modulusDec.description, "exponent": exponentDec.description] as [String: String]
            guard let modulusAndExponentJSON = dict.json else { return nil }
            let modulusAndExponent = modulusAndExponentJSON.filter { !" \n".contains($0) }
            let str = "{\"modulus\":\"\(modulusDec.description)\",\"exponent\":\"\(exponentDec.description)\"}"
            return str.base64Encoded() ?? nil
        }
        return nil
    }
    

    static func isValidData(signedUrl: String, serverURL: String) -> Bool {
        if let upsideDown = serverURL.data(using: .utf16LittleEndian) {
            do {
                
                let publicKey = try PublicKey(pemNamed: "identite.pubkey")
                let sign = try! Signature(base64Encoded: signedUrl)
                let clear = ClearMessage(data: upsideDown)
                return CryptoKeyService.isSuccessfulSignature(sign, publicKey: publicKey, clear: clear,digestType: .sha256)
            } catch {
                logMessage("Invalid data")
                return false
            }
        }
        return false
    }
    
    
    
    static func getModAndExpFrom(publicKey: SecKey) -> (mod: Data, exp: Data)? {
        
        let pubAttributes = SecKeyCopyAttributes(publicKey) as! [String: Any]
        
        // Check that this is really an RSA key
        guard Int(pubAttributes[kSecAttrKeyType as String] as! String)
            == Int(kSecAttrKeyTypeRSA as String) else {
                return nil
        }
        
        // Check that this is really a public key
        guard Int(pubAttributes[kSecAttrKeyClass as String] as! String)
            == Int(kSecAttrKeyClassPublic as String)
            else {
                return nil
        }
        
        
        let keySize = pubAttributes[kSecAttrKeySizeInBits as String] as! Int
        
        // Extract values
        let pubData = pubAttributes[kSecValueData as String] as! Data
        var modulus = pubData.subdata(in: 8..<(pubData.count - 5))
        let exponent = pubData.subdata(in: (pubData.count - 3)..<pubData.count)
        
        if modulus.count > keySize / 8 { // --> 257 bytes
            modulus.removeFirst(1)
        }
        
        return (mod: modulus, exp: exponent)
    }
    
    
    static func decryptedMessage(_ message: String, privateKey: PrivateKey) -> String {
        let encrypted = try? EncryptedMessage(base64Encoded: message)
        let clear = try? encrypted?.decrypted(with: privateKey, padding: .PKCS1)
        let string = try? clear?.string(encoding: .utf8)
        return string ?? ""
    }
    
    
    
    static func getSignature(_ string: String, privateKey: PrivateKey, publicKey: PublicKey?) -> String? {
        var clear: ClearMessage?
        var signature: Signature?
        repeat {
            clear = try? ClearMessage(string: string, using: .utf8)
            signature = try? clear?.signed(with: privateKey, digestType: .sha512)
        } while publicKey != nil && isSuccessfulSignature(signature, publicKey: publicKey, clear: clear) == false;
        
        let base64String = signature?.base64String
        return base64String
    }
    
    static func getSecure(id: String, privateKey: PrivateKey, publicKey: PublicKey? = nil) -> String {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return ""
        }
        var str: String = ""
        if NoPassSDKReact.secretKey.isEmpty {
            str = "\(bundleID)#\(id)"
        } else {
            str = "\(NoPassSDKReact.secretKey)#\(bundleID)#\(id)"
        }
//        print("Secure string \(str)")
        
        return getSignature(str, privateKey: privateKey, publicKey: publicKey) ?? ""
    }    
    
    static func isSuccessfulSignature(_ signature: Signature?, publicKey: PublicKey?, clear: ClearMessage?, digestType: Signature.DigestType = .sha512) -> Bool {
        guard let signature = signature, let publicKey = publicKey, let clear = clear else {
            return false
        }
        
        let isSuccessful = try? clear.verify(with: publicKey, signature: signature, digestType: digestType)
        return isSuccessful ?? false
    }
    
}


