import Foundation

final class AccountService: AccountServiceProtocol {
   
    private let network: NetworkManager
    private let checkApiManger: CheckApiManger
    
    init(_ network: NetworkManager = NetworkManager(), checkApiManger: CheckApiManger = CheckApiManger()) {
        self.network = network
        self.checkApiManger = checkApiManger
    }
    
    
    
    func deleteInitialDevice(_ userId: String, userCode: String,portalId: String, deviceId: String, serverUrl: String, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((String?, String?, String?,NSError?) -> Void)?) {
        
        checkApiManger.checkServerVersion(serverUrl, apiVersionFlowType: .delete) { (result, error) in
            if let versionError = error {
                completion?(nil, nil, nil, versionError)
            }
            
            
            
            let apiPath = "\(serverUrl)api/UserDelete/DeleteInitialDevice"
            let tag = REQUEST_TAG.deleteInitialDevice.rawValue
            //TODO : userCode
            let dict: [String: Any] = ["userId": userId,
                                       "portalId": portalId,
                                       "deviceId": deviceId,
                                       "userCode": userCode,
                                       "device": DeviceDataModel(isScreenLock: isScreenLock, enabled2FaMethod: enabled2FaMethod).toDictionary()]
            
            self.network.sendRequest(urlString:apiPath, params: dict, completion: { (json, error) in
                if let error = error {
                    completion?(nil, nil, nil, error)
                } else if let jsonResult = json as? JSON {
                    let sessionId = jsonResult["result"]["sessionId"].stringValue
                    let encryptedData = jsonResult["result"]["encryptedData"].stringValue
                    let signedUrl = jsonResult["result"]["signedUrl"].stringValue
                    completion?(sessionId, encryptedData, signedUrl, nil)
                }
            }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
            
        }
        
    }
    
    
    
    func deleteConfirmation(_ encryptedData: String, sessionId: String, secure: String ,serverUrl: String, completion: NetworkManager.CompletionBlock?) {
        
        let apiPath = "\(serverUrl)api/UserDelete/DeleteConfirmation"
        let tag = REQUEST_TAG.deleteConfirmation.rawValue
        
        
        let dict: [String: Any] = ["encryptedData": encryptedData,
                                   "sessionId": sessionId,
                                   "SecureString": secure]
        
        network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            
            if let error = error {
                if error.code == 1603 || error.code == 1605 || error.code == 1610  {
                    completion?(nil, nil)
                    return
                }
                completion?(nil, error)
            } else if let jsonResult = json as? JSON {
                let result = jsonResult["result"].stringValue
                completion?(result, error)
            }
            
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
    }
    
    
    
    // MARK: UPDATE
    
    func updateInitialDevice(_ userId: String, userCode: String, portalId: String, deviceId: String,serverUrl: String,accountUpdates: AccountUpdatesModel, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((String?,String?, String?,Bool,NSError?) -> Void)?) {
        
        checkApiManger.checkServerVersion(serverUrl, apiVersionFlowType: .update) { (serverVersion, error) in
            
            var isNeedCheckSign: Bool = false
            
            if let versionError = error {
                completion?(nil,nil,nil,isNeedCheckSign,versionError)
            } else if let serverVersion = serverVersion {
                let appVersion = ApiVersionModel()
                
                if let appUpdateVersion = Double(appVersion.userUpdatingVersion), let serverUpdateVersion = Double(serverVersion.userUpdatingVersion) {
                    isNeedCheckSign = serverUpdateVersion >= appUpdateVersion
                }
                
            }
            
            
            
            
            let apiPath = "\(serverUrl)api/UserUpdate/UpdateInitialDevice"
            let tag = REQUEST_TAG.updateInitialDevice.rawValue
            
            let dict: [String: Any] = ["userId": userId,
                                       "userCode": userCode,
                                       "portalId": portalId,
                                       "deviceId": deviceId,
                                       "device": DeviceDataModel(isScreenLock: isScreenLock, enabled2FaMethod: enabled2FaMethod).toDictionary(),
                                       "updates" : accountUpdates.toDictionary()]
            
            self.network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
                if let error = error {
                    completion?(nil,nil,nil,isNeedCheckSign,error)
                } else if let jsonResult = json as? JSON {
                    let sessionId = jsonResult["result"]["sessionId"].stringValue
                    let encryptedData = jsonResult["result"]["encryptedData"].stringValue
                    let signedUrl = jsonResult["result"]["signedUrl"].stringValue
                    completion?(signedUrl, sessionId, encryptedData,isNeedCheckSign,nil)
                }
            }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
            
        }
        
        
    }
    
    
    
    func updateConfirmation(_ encryptedData: String, sessionId: String,secure: String ,serverUrl: String, completion: NetworkManager.CompletionBlock?) {
        let apiPath = "\(serverUrl)api/UserUpdate/UpdateConfirmation"
        let tag = REQUEST_TAG.updateConfirmation.rawValue
        
        let dict: [String: Any] = ["encryptedData": encryptedData,
                                   "sessionId": sessionId,
                                   "SecureString": secure]
        
        network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            if let error = error {
                completion?(nil, error)
            } else if let jsonResult = json as? JSON {
                let result = jsonResult["result"].stringValue
                completion?(result, error)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
        
    }
    
}

