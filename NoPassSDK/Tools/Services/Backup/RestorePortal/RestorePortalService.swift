

final class RestorePortalService : RestorePortalServiceProtocol {

    let network: NetworkManager
    
    init(network: NetworkManager = NetworkManager()) {
        self.network = network
    }
    
    func restore(serverUrl: String, userCode: String ,userId: String, portalId: String, portalName: String, pinCode: String , enabled2FaMethod: BiometricType, isScreenLock: Bool, comletion: ((UserMetaData?, Error?) -> ())?) {
        let apiPath = "\(serverUrl)api/UserRestore/RestoreRequest"
        let tag = REQUEST_TAG.restore.rawValue
        let dict: [String: Any] = ["UserCode": userCode,
                                   "UserId" : userId,
                                   "PortalId" : portalId,
                                   "Device" : DeviceDataModel(isScreenLock: isScreenLock, enabled2FaMethod: enabled2FaMethod).toDictionary()]
        
        self.network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            
            if let jsonResult = json as? JSON, let sessionId = jsonResult["result"]["sessionId"].string {
                self.restoreConfirmation(serverUrl: serverUrl, sessionId: sessionId, backupHash: String(pinCode.suffix(4)).sha256(), portalName: portalName) { (user, error) in
                    comletion?(user,error)
                }
            } else if let error = error {
                comletion?(nil,error)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
    }
    
    
    func restoreConfirmation(serverUrl: String, sessionId: String, backupHash: String, portalName: String, comletion: ((UserMetaData?, Error?) -> ())?) {
        let apiPath = "\(serverUrl)api/UserRestore/RestoreConfirmation"
        let tag = REQUEST_TAG.restoreConfirmation.rawValue
        let dict: [String: Any] = ["SessionId" : sessionId,
                                   "BackupHash" : backupHash]
        
        
        self.network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            if let jsonResult = json as? JSON {
                let user = UserMetaData(json: jsonResult["result"], portalName: portalName, serverUrl: serverUrl)
                comletion?(user,error)
            } else if let error = error {
                comletion?(nil,error)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
        
    }
    
}
