//
//  AuthenticationService.swift
//  Mapd
//
//  Created by Влад on 10/22/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

final class AuthenticationService: AuthenticationServiceProtocol {
    
    private let network: NetworkManager
    private let checkApiManger: CheckApiManger
    
    init() {
        self.network = NetworkManager()
        self.checkApiManger = CheckApiManger()
    }
    
    
    func doVerifyDevice(_ auth: AuthModel, serverUrl: String, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((_ timestamp: String?,_ signedUrl: String?,_ delta: TimeInterval?,_ error: NSError?) -> Void)?) {
        
        self.getDelay(serverUrl) { (delta, error) in
            if let versionError = error {
                completion?(nil, nil, nil,versionError)
            }
            
            guard let delta = delta else {
                completion?(nil, nil, nil,error)
                return
            }
            
            let apiPath = "\(serverUrl)api/UserAuthentication/VerifyDevice"
            let tag = REQUEST_TAG.authVarifyDevice.rawValue
            
            
            let dict: [String: Any] = ["portalId": auth.portalId,
                                       "portalUrl": auth.portalUrl,
                                       "userName": auth.username,
                                       "r": (auth.r + 1),
                                       "device": DeviceDataModel(isScreenLock: isScreenLock, enabled2FaMethod: enabled2FaMethod).toDictionary(),
                                       "authId": auth.authId,
                                       "userCode": auth.userCode]
            
            self.network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
                if let jsonResult = json as? JSON {
                    let timestamp = jsonResult["result"]["timestamp"].stringValue
                    let signedUrl = jsonResult["result"]["signedUrl"].stringValue
                    completion?(timestamp,signedUrl,delta,error)
                } else {
                    completion?(nil,nil,nil,error)
                }
            }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
        }
        
        
    }
    
    func getDelay(_ serverUrl: String ,completion: ((_ delta: TimeInterval?,_ error: NSError?) -> Void)?) {
        let startDate = Date()
        
        checkApiManger.checkServerVersion(serverUrl, apiVersionFlowType: .auth) { (result, error) in
            if let versionError = error {
                completion?(nil,versionError)
            }
            
            guard let result = result else {
                completion?(nil ,error)
                return
            }
            
            let durationTime = Date().timeIntervalSince(startDate)
            
            let serverTime = Date(timeIntervalSince1970: result.serverDate.timeIntervalSince1970 + Double(durationTime / 2))
            
            let delta = serverTime.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate
            
            completion?(delta,nil)
        }
    }
    
    
    func authorize(signature: String, authId: String, answer: Bool, reason: String, timeStamp: String, serverUrl: String, secure: String, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: NetworkManager.CompletionBlock?) {
        let apiPath = "\(serverUrl)api/UserAuthentication/Authorize"
        let tag = REQUEST_TAG.authorize.rawValue
        
        let dict: [String: Any] = ["signature": signature,
                                   "SecureString": secure,
                                   "authId": authId,
                                   "answer": answer,
                                   "reason": reason,
                                   "timeStamp": timeStamp,
                                   "device": DeviceDataModel(isScreenLock: isScreenLock, enabled2FaMethod: enabled2FaMethod).toDictionary()]
        
        network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            
            if let error = error {
                completion?(nil, error)
            } else if let jsonResult = json as? JSON {
                completion?(jsonResult["result"].boolValue, nil)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
        
        
        
    }
}

