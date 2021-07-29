//
//  UserStorage.swift
//  Mapd
//
//  Created by Влад on 9/24/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

final class UserStorage {
    
    static private let pinKey: String = "UserPinCode"
    static private let pushTokenKey: String = "FirebasePushToken"
    static private let useerSeedKey: String = "useerSeedKey"
    static private let islaunchedBeforeKey: String =  "islaunchedBefore"
    static private let lastAuthDate: String =  "lastAuthDate"
    static private let backupPinCode: String =  "backupPinCode"
    
    
    
    // MARK: - Access Token
    static func setPushToken(value: String) {
        KeychainSwift().set(value, forKey: pushTokenKey)
    }
    
    static func getPushToken() -> String? {
        return KeychainSwift().get(pushTokenKey)
    }
    
    
    // MARK: PIN CODE
    
    static func setPinCode(value: String) {
        KeychainSwift().set(value, forKey: pinKey)
    }
    
    static func getPinCode() -> String? {
        return KeychainSwift().get(pinKey)
    }
    
    static func deletePinCode() {
        KeychainSwift().delete(pinKey)
    }
    
    
    static func cleareKeychain() {
        KeychainSwift().clear()
    }
    
    static func islaunchedBefore() -> Bool {
        return UserDefaults.standard.bool(forKey: islaunchedBeforeKey)
    }
    
    static func setFirstLaunchValue(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: islaunchedBeforeKey)
    }
    
    
    
    // MARK: AUTH DATE
    
    static func setLastAuthDate(value: String) {
        KeychainSwift().set(value, forKey: lastAuthDate)
    }
    
    static func getLastAuthDate() -> String? {
        return KeychainSwift().get(lastAuthDate)
    }
    
    static func deleteLastAuthDate() {
        KeychainSwift().delete(lastAuthDate)
    }
    
    
    
    // MARK: BACKUP PIN CODE
    
    static func setBackupPinCode(value: String) {
        KeychainSwift().set(value, forKey: backupPinCode)
    }
    
    static func getBackupPinCode() -> String? {
        return KeychainSwift().get(backupPinCode)
    }
    
    static func deleteBackupPinCode() {
        KeychainSwift().delete(backupPinCode)
    }
}

