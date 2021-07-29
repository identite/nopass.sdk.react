//
//  NoPassConfigurator.swift
//  NoPassSDK
//
//  Created by Artsiom Shmaenkov on 9.07.21.
//  Copyright © 2021 PSA. All rights reserved.
//

import Foundation

@objc public class NoPassConfigurator: NSObject {
    @objc public static func setSecretKey(_ key: String) {
        secretKey = key
    }

    @objc public static func setCurrentGPSCordinate(_ latitude: Double, longitude: Double) {
        currentGPSCordinate = GpsLocationModel(latitude: latitude, longitude: longitude)
    }
    
    @objc public static func enableLogs(_ enabled: Bool) {
        setLogEnabled(enabled)
    }
}
