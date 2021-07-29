//
//  KeyStore.swift
//  Mapd
//
//  Created by Влад on 10/4/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation
//import KeychainSwift
//import SwiftyRSA

final class KeyStorage {

    static private let privatePartKey: String = "privatePartKey"
    static private let publicPartKey: String = "publicPartKey"

    // MARK: - Access Token

    static func saveKeyPair(key: String, publicKey: PublicKey, privateKey: PrivateKey) {
        let publicBase64 = try? publicKey.base64String()
        let privateBase64 = try? privateKey.base64String()
        savePublicKey(key: key, publicKey: publicBase64 ?? "")
        savePrivateKey(key: key, privateKey: privateBase64 ?? "")
    }

    static func savePrivateKey(key: String, privateKey: String) {
        KeychainSwift().set(privateKey, forKey: "\(privatePartKey)-\(key)")
    }

    static func savePublicKey(key: String, publicKey: String) {
        KeychainSwift().set(publicKey, forKey: "\(publicPartKey)-\(key)")
    }
    
    
    static func removeKeyPair(key: String) {
        KeychainSwift().delete("\(publicPartKey)-\(key)")
        KeychainSwift().delete("\(privatePartKey)-\(key)")
    }
    
    

    static func getKeyPair(key: String) -> (privateKey: PrivateKey, publicKey: PublicKey)? {
        let keyPair = (getPrivateKey(key: key), getPublicKey(key: key))
        guard let privateKey = keyPair.0, let publicKey = keyPair.1 else { return nil }
        return (privateKey, publicKey)
    }


    static func getPrivateKey(key: String) -> PrivateKey? {
        guard let privateBase64 = KeychainSwift().get("\(privatePartKey)-\(key)") else { return nil }
        let privateKey = try? PrivateKey(base64Encoded: privateBase64)
        return privateKey
    }

    static func getPublicKey(key: String) -> PublicKey? {
        guard let publicBase64 = KeychainSwift().get("\(publicPartKey)-\(key)") else { return nil }
        let publicKey = try? PublicKey(base64Encoded: publicBase64)
        return publicKey
    }
}
