//
//  RegistrationService.swift
//  Mapd
//
//  Created by Влад on 10/7/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation
import UIKit

public class RegistrationService: RegistrationServiceProtocol {
  
    private let network: NetworkManager
    private let checkApiManger: CheckApiManger
    
    init() {
        self.network = NetworkManager()
        self.checkApiManger = CheckApiManger()
    }
    
    open func doConfirmRegistration( otp: String, serverUrl: String, completion: ((String?, Bool?, Error?) -> ())?) {
        
        let apiPath = "\(serverUrl)api/UserRegistration/ConfirmRegistration"
        let tag = REQUEST_TAG.assignDevice.rawValue
        
        let dict: [String: String] = ["otp": otp]
        
        network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            
            if let error = error {
                completion?(nil,nil ,error)
            } else if let jsonResult = json as? JSON {
                let result = jsonResult["result"]
                let userCode = result["userCode"].string
                let IsSuccess = result["isSuccess"].bool
                completion?(userCode,IsSuccess,nil)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
    }
    
    func doConfirmApp(_ user: UserMetaData, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: NetworkManager.CompletionBlock?) {
        let apiPath = "\(user.serverUrl)api/UserRegistration/ConfirmApp"
        let tag = REQUEST_TAG.confirmApp.rawValue
        var dict = user.toDictionary()
        dict["device"] = DeviceDataModel(isScreenLock: isScreenLock, enabled2FaMethod: enabled2FaMethod).toDictionary()
        network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            if let jsonResult = json as? JSON {
                completion?(jsonResult["result"]["signedUrl"].stringValue, error)
            } else {
                completion?(nil, error)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
        
    }
    
    func doAssigneDevice(_ deviceId: String, otp: String, serverUrl: String, completion: NetworkManager.CompletionBlock?) {
        
        let apiPath = "\(serverUrl)api/UserRegistration/AssignDevice"
        let tag = REQUEST_TAG.assignDevice.rawValue
        
        let dict: [String: String] = ["deviceId": deviceId,
                                      "otp": otp]
        
        
        network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            if let jsonResult = json as? JSON {
                completion?(jsonResult, nil)
            } else {
                completion?(nil, error)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
        
    }
    
    func doVerifyDevice(_ user: UserMetaData, r: Int, token: String,completion: NetworkManager.CompletionBlock?) {
        
        checkApiManger.checkServerVersion(user.serverUrl, apiVersionFlowType: .registration) { (result, error) in
            if let versionError = error {
                completion?(nil, versionError)
            }
            let apiPath = "\(user.serverUrl)api/UserRegistration/VerifyDevice"
            let tag = REQUEST_TAG.verifyDevice.rawValue
            
            let hashString: String = "\(user.portalid)#\(user.username)#\(token)".sha256()
            
            let deviceHygiene: [String: Any] = ["isRooted": Device.isJailbreak(),
                                                "os": "iOS",
                                                "version": UIDevice.current.systemVersion]
            
            let dict: [String: Any] = ["r": r + 1,
                                       "userId": user.username,
                                       "hash": hashString,
                                       "deviceHygiene": deviceHygiene,
                                       "otp": user.otp,
                                       "confirmid": user.confirmid,
                                       "userCode": user.userCode]
            
            
            self.network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
                if let jsonResult = json as? JSON {
                    let verify = VerifyDeviceModel(json: jsonResult["result"])
                    completion?(verify, error)
                } else {
                    completion?(nil, error)
                }
            }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
        }
    }
    
    func doKeyApply(_ otp: String, encodedPublicKey: String, signature: String, data: [String : Any], r2: Int, serverUrl: String, timeoutInterval: Double, secure: String, completion: ((String?, String?, Error?) -> ())?)  {
        
        let apiPath = "\(serverUrl)api/UserRegistration/KeyApply"
        let tag = REQUEST_TAG.keyApply.rawValue
                
        let dict: [String: Any] = ["publicKeyX": encodedPublicKey,
                                   "data": data,
                                   "signature": signature,
                                   "r2": r2,
                                   "otp": otp,
                                   "SecureString": secure]
        
        
        network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            if let error = error {
                completion?(nil,nil,error)
            } else if let jsonResult = json as? JSON {
                let result = jsonResult["result"]
                let userCode = result["userCode"].string
                let encryptedData = result["encryptedData"].string
                completion?(userCode, encryptedData ,nil)
            }
            
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag,timeoutInterval: timeoutInterval)
    }
    
    func doSyncUser(serverUrl: String, portalId: String, userCode: String, deviceId: String, clientIp: String, date: String, secure: String, completion: NetworkManager.CompletionBlock?) {
        let apiPath = "\(serverUrl)api/UserRegistration/SyncUser"
        let tag = REQUEST_TAG.syncUser.rawValue
        
        let dict: [String: Any] = ["portalId": portalId,
                                   "userCode": userCode,
                                   "deviceId": deviceId,
                                   "clientIP": clientIp,
                                   "date": date,
                                   "secureString": secure]
        
        network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            if let jsonResult = json as? JSON {
                completion?(jsonResult["result"]["referrer"].stringValue, error)
            } else {
                completion?(nil, error)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
    }
    
    func doInitUser(serverUrl: String, syncId: String, portalId: String, userCode: String, deviceId: String, syncDataArray: [SyncData], completion: NetworkManager.CompletionBlock?) {
        let apiPath = "\(serverUrl)api/UserRegistration/InitSync"
        let tag = REQUEST_TAG.initSync.rawValue
        
        let dict: [String: Any] = ["syncId": syncId,
                                    "portalId": portalId,
                                   "userCode": userCode,
                                   "deviceId": deviceId,
                                   "syncData": syncDataArray.map { $0.toDictionary() }]
        
        network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            if let jsonResult = json as? JSON {
                completion?(jsonResult["result"].boolValue, error)
            } else {
                completion?(nil, error)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
    }
    
    func doGetSyncLinks(serverUrl: String, syncId: String, confirmId: String, deviceId: String, secure: String, completion: NetworkManager.CompletionBlock?) {
        let apiPath = "\(serverUrl)api/UserRegistration/GetSyncLinks"
        let tag = REQUEST_TAG.getSyncLinks.rawValue
        
        let dict: [String: Any] = ["syncId": syncId,
                                   "secureString": secure,
                                   "deviceId": deviceId,
                                   "confirmId": confirmId]
        
        network.sendRequest(urlString: apiPath, params: dict, completion: { (json, error) in
            if let jsonResult = json as? JSON {
                let qrCodeArray = jsonResult["result"].arrayValue.map({ $0["qrCode"].stringValue })
                completion?(qrCodeArray, error)
            } else {
                completion?(nil, error)
            }
        }, method: "POST", urlEncoding: JSONEncoding.default, requestTag: tag)
        
    }
}

