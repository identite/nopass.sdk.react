//
//  DeviceDataModel.swift
//  Mapd
//
//  Created by Влад on 12/12/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation
import UIKit

// TODO: CHECK  GPS

public enum BiometricType : String {
    case null = "null"
    case NativeFingerPrint = "NativeFingerPrint"
    case NativeFaceId = "NativeFaceId"
    case NativePinCode = "NativePinCode"
    case PinCode = "PinCode"
}

class DeviceDataModel {
    
    let osName: String
    let osVersion: String
    let appVersion: String
    let isRooted: Bool
    let isScreenLock: Bool
    let deviceId: String
    
    let enabled2FaMethod: BiometricType
    let apiVersion: ApiVersionModel
    let gpsLocation: GpsLocationModel
    let model: String
    
    init(isScreenLock: Bool, enabled2FaMethod: BiometricType? = nil) {
        self.osName = "iOS"
        self.osVersion = UIDevice.current.systemVersion
        //TODO: Add app version
        self.appVersion = AppConfig.APP_VERSION
        self.isRooted =  Device.isJailbreak()
        self.isScreenLock = isScreenLock
        
        if let enabled2FaMethod = enabled2FaMethod {
            self.enabled2FaMethod = enabled2FaMethod
        } else {
            self.enabled2FaMethod = .null
        }
        
        self.apiVersion = ApiVersionModel()
        self.model = UIDevice.current.modelName
        self.deviceId = UserStorage.getPushToken() ?? ""
        
        self.gpsLocation = currentGPSCordinate ?? GpsLocationModel(latitude: 0.0, longitude: 0.0)
    }
}


extension DeviceDataModel {
    func toDictionary() -> [String: Any] {
        var result: [String: Any] = [:]
        result["osName"] = self.osName
        result["osVersion"] = self.osVersion
        result["appVersion"] = self.appVersion
        result["isRooted"] = self.isRooted
        result["isScreenLock"] = self.isScreenLock
        result["model"] = self.model
        result["deviceId"] = self.deviceId
        if self.enabled2FaMethod != .null {
            result["enabled2FaMethod"] = self.enabled2FaMethod.rawValue
        }
        result["GpsLocation"] = self.gpsLocation.toDictionary()
        result["apiVersion"] = apiVersion.toDictionary()
        return result
    }
}
