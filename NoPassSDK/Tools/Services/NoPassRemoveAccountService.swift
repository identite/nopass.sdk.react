import Foundation

public class NoPassRemoveAccountService {
    
    public static var shared = NoPassRemoveAccountService()
    
    let accountService: AccountService = AccountService()
    
    
    public func deleteDevice(account: NoPassAccount, session: String, isNeedUpdateBackup: Bool = true, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((_ error: NSError?) -> Void)?) {
        guard let portal = CoreDataManager.shared.getAccount(userCode: account.userCode) else {
            return
        }
        
        guard let deviceId = UserStorage.getPushToken(), let userName = portal.userName, let userCode = portal.userCode, let portalId = portal.portalId, let serverUrl = portal.serverUrl, let userseed = portal.userseed, let alias = portal.alias else { return }
        accountService.deleteInitialDevice(userName, userCode: userCode, portalId: portalId, deviceId: deviceId, serverUrl: serverUrl, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock) { [weak self] (sessionId, encryptedData, signedUrl, error) in
            
            guard let strongSelf = self else { return }
            
            if let error = error {
                if error.code == 1603 || error.code == 1605 || error.code == 1610 {
                    
                    let signature = strongSelf.getSignature(alias: portal.alias ?? "", strValue: "\(session)#\(userseed)")
                    let secure = strongSelf.getSecure(alias: portal.alias ?? "", strValue: session)
                    strongSelf.deleteConfirmation(session, encryptedData: signature, secure: secure, portal: portal, isNeedUpdateBackup: isNeedUpdateBackup) { (confirmError) in
                        completion?(confirmError)
                    }
                    return
                } else {
                    completion?(error)
                }
                
            } else if let sessionId = sessionId, let signedUrl = signedUrl {
                if !CryptoKeyService.isValidData(signedUrl: signedUrl, serverURL: portal.serverName) {
                    completion?(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid signature"]))
                    return
                }
                
                let signature = strongSelf.getSignature(alias: alias, strValue: "\(sessionId)#\(userseed)")
                
                let secure = strongSelf.getSecure(alias: alias, strValue: session)
                strongSelf.deleteConfirmation(sessionId, encryptedData: signature, secure: secure, portal: portal, isNeedUpdateBackup: isNeedUpdateBackup) { (confirmError) in
                    completion?(confirmError)
                }
            }  else {
                let signature = strongSelf.getSignature(alias: alias, strValue: "\(session)#\(userseed)")
                
                let secure = strongSelf.getSecure(alias: alias, strValue: session)
                
                strongSelf.deleteConfirmation(session, encryptedData: signature, secure: secure, portal: portal, isNeedUpdateBackup: isNeedUpdateBackup) { (confirmError) in
                    completion?(confirmError)
                }
            }
        }
        
    }
    
    
    func getSignature(alias: String, strValue: String) -> String {
        let privateKey = KeyStorage.getPrivateKey(key: alias)
        let signature = CryptoKeyService.getSignature(strValue, privateKey: privateKey!) ?? ""
        return signature
    }
    
    func getSecure(alias: String, strValue: String) -> String {
        if let privateKey = KeyStorage.getPrivateKey(key: alias) {
            let signature = CryptoKeyService.getSecure(id: strValue, privateKey: privateKey)
            return signature
        }
        return ""
    }
    
    private func deleteConfirmation(_ sessionId: String, encryptedData: String,secure: String ,portal: Account, isNeedUpdateBackup: Bool,completion:((_ error: NSError?) -> Void)?) {
        
        let secure1 = getSecure(alias: portal.alias ?? "" , strValue: sessionId)
        
        accountService.deleteConfirmation(encryptedData, sessionId: sessionId, secure: secure1, serverUrl: portal.serverUrl ?? "") { [weak self] (result, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                completion?(error)
                return
            }
            strongSelf.removePortal(portal: portal, isNeedUpdateBackup: isNeedUpdateBackup)
            completion?(nil)
        }
    }
    
    private func removePortal(portal: Account,isNeedUpdateBackup: Bool) {
        
        KeyStorage.removeKeyPair(key: portal.alias ?? "")
        CoreDataManager.shared.removeAccount(account: portal)
//        let history = Array(RealmManager.shared.getObjects(type: AuthHistoryModel.self)) as! [AuthHistoryModel]
//        RealmManager.shared.deleteObject(items: history.filter({ $0.portalUrl == portal.portalUrl && $0.userName == portal.userName }))
//        let dict = portal.toDictionary()
//        RealmManager.shared.deleteObject(items: [portal])
//        if isNeedUpdateBackup {
//            AccountsObserverManager.shared.updateBackupOnGoogleDrive()
//        }
    }
    
    
}

