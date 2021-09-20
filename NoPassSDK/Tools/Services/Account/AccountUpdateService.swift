//
//  PortalService.swift
//  Mapd
//
//  Created by Vlad Krupnik on 24/01/2020.
//  Copyright © 2020 PSA. All rights reserved.
//

import Foundation

final class AccountUpdateService {

    static var shared = AccountUpdateService()

    var accountService: AccountService = AccountService()
    
    var accountUpdates: AccountUpdatesModel?
  
    
    init(_ accountService: AccountService = AccountService()) {
        self.accountService = accountService
    }
    
    func setAccountUpdatesModel(accountUpdatesModel: AccountUpdatesModel) {
        self.accountUpdates = accountUpdatesModel
    }
    
    func updateDevice(portal: Account, enabled2FaMethod: BiometricType, isScreenLock: Bool) {
        guard let deviceId = UserStorage.getPushToken(), let accountUpdates = accountUpdates/*, accountUpdates.login.newValue.isEmpty*/ else { return }
    
        if accountUpdates.login.newValue.isEmpty {
            return
        }
        
        guard let userCode = portal.userCode, let portalId = portal.portalId, let serverUrl = portal.serverUrl, let alias = portal.alias, let userseed = portal.userseed else {
            return
        }
        
        accountService.updateInitialDevice(accountUpdates.login.newValue,userCode:
        userCode ,portalId: portalId, deviceId: deviceId, serverUrl: serverUrl,  accountUpdates: accountUpdates, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock) { [weak self] ( signedUrl, sessionId, encryptedData, isNeedCheckSign,error) in
            
            guard let strongSelf = self else { return }
            
            if let sessionId = sessionId, let encryptedData = encryptedData, let signedUrl = signedUrl {
                debugPrint(encryptedData)
                if isNeedCheckSign {
                    if !CryptoKeyService.isValidData(signedUrl: signedUrl, serverURL: portal.serverName) {
                        logMessage("Invalid signed")
                        return
                    }
                }
              
                let privateKey = KeyStorage.getPrivateKey(key: alias)
                let publicKey = KeyStorage.getPublicKey(key: alias)
                let signature = CryptoKeyService.getSignature("\(sessionId)#\(userseed)", privateKey: privateKey!, publicKey: publicKey)
                strongSelf.updateConfirmation(sessionId, encryptedData: signature!, portal: portal)
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    
    private func updateConfirmation(_ sessionId: String, encryptedData: String, portal: Account) {
        guard let accountUpdatesModel = accountUpdates else {
            return
        }
        
        guard let userCode = portal.userCode, let portalId = portal.portalId, let serverUrl = portal.serverUrl, let alias = portal.alias, let userName = portal.userName else {
            return
        }
        let secure = self.getSecure(alias: alias, strValue: sessionId)
        accountService.updateConfirmation(encryptedData, sessionId: sessionId, secure: secure, serverUrl: serverUrl) { [weak self] (result, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                logMessage(error.localizedDescription)
                return
            }
            strongSelf.updatePortal(portalID: portalId, userCode: userCode, username: userName, newUsername: accountUpdatesModel.login.newValue)
        }
    }
    
    func getSecure(alias: String, strValue: String) -> String {
        if let privateKey = KeyStorage.getPrivateKey(key: alias) {
            let signature = CryptoKeyService.getSecure(id: strValue, privateKey: privateKey)
            return signature
        }
        return ""
    }
    
    
    
    func updatePortal(portalID: String, userCode: String, username: String, newUsername: String) {
        CoreDataManager.shared.update(userCode: userCode, name: newUsername)
//        if let portal = (Array((RealmManager.shared.getObjects(type: PortalInfoModel.self))) as? [PortalInfoModel])?.first(where: { $0.portalName == portalID && $0.userCode == userCode }) {
//
//
//
//            let realm = RealmManager.shared.realm
////            let newPortal = PortalInfoModel(userName: newUsername, portalName: portalID, userseed: portal.userseed, portalUrl: portal.portalUrl, serverUrl: portal.serverUrl, logoColor: portal.logoColor, alias: portal.alias)
//            // TO DO: CHANGE PORTAL URL TO ID
//            updateHistory(portalID: portalID, username: username, userCode: userCode, newUsername: newUsername)
//
//
//            try! realm.write {
//
//                portal.userName = newUsername
//                realm.add(portal, update: .all)
//                NotificationCenter.default.post(name: .onAccountsChange, object: self, userInfo: portal.toDictionary())
//            }
//        }
    }

//    private func updateHistory(portalID: String, username: String, userCode: String, newUsername: String) {
//        let portalHistory = (Array((RealmManager.shared.getObjects(type: AuthHistoryModel.self))) as? [AuthHistoryModel])?.filter({ $0.userCode == userCode && $0.portalId == portalID })
//        let realm = RealmManager.shared.realm
//        try! realm.write {
//            portalHistory?.forEach({ (history) in
//                history.userName = newUsername
//                realm.add(history, update: .all)
//            })
//        }
//    }
}
