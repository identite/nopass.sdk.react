import Foundation

final class BackupServerService : BackupServerServiceProtocol {
    
    let network: NetworkManager
    private let checkApiManger: CheckApiManger
    
    
    init(_ network: NetworkManager = NetworkManager(), checkApiManger: CheckApiManger = CheckApiManger()) {
        self.network = network
        self.checkApiManger = checkApiManger
    }
    
    
    
    
    func backupRequest(portal: Account, deviceId: String, pin: String, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((Error?) -> ())?) {
        
        let apiPath = "\(portal.serverUrl ?? "")api/UserRestore/BackupRequest"
        let tag = REQUEST_TAG.backup.rawValue
        let dict: [String: Any] = ["portalId": portal.portalId ?? "",
                                   "DeviceId": deviceId ,
                                   "UserId": portal.userName ?? "",
                                   "UserCode": portal.userCode ?? 0,
                                   "Device": DeviceDataModel(isScreenLock: isScreenLock, enabled2FaMethod: enabled2FaMethod).toDictionary()]
        
        self.network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            if let jsonResult = json as? JSON {
                
                let sessionId = jsonResult["result"]["sessionId"].stringValue
                let encryptedData = jsonResult["result"]["encryptedData"].stringValue
                let signedUrl = jsonResult["result"]["signedUrl"].stringValue
                
                if !CryptoKeyService.isValidData(signedUrl: signedUrl, serverURL: portal.serverName) {
                    completion?(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid signature"]))
                    return
                }
                self.backupConfirmation(portal: portal, sessionId: sessionId, pin: pin) { (error) in
                    completion?(error)
                }
            } else if let error = error {
                completion?(error)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
        
    }
    
    
    
    
    func backupConfirmation(portal: Account, sessionId: String, pin: String, completion: ((Error?) -> ())?) {
        
        guard let userCode = portal.userCode, let portalName = portal.portalName, let serverUrl = portal.serverUrl, let alias = portal.alias, let userseed = portal.userseed else {
            return
        }
        
        let apiPath = "\(serverUrl)api/UserRestore/BackupConfirmation"
        let tag = REQUEST_TAG.backupConfirmation.rawValue
        
        let signature = getSignature(alias: alias, strValue: "\(sessionId)#\(userseed)")
        
        let secure = getSecure(alias: alias, strValue: sessionId)
        
        let dict: [String: Any] = ["EncryptedData" : signature,
                                   "SessionId": sessionId,
                                   "SecureString": secure,
                                   "BackupHash": String(pin.suffix(4)).sha256()]
        
        
        self.network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            completion?(error)
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
        
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
    
}



