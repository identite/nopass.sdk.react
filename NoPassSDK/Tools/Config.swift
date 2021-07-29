//
//  Config.swift
//  NoPassSDK
//
//  Created by Vlad Krupnik on 05.01.2021.
//  Copyright © 2021 PSA. All rights reserved.
//

import Foundation
// SecretKey for NoPass App
var secretKey: String = ""

var currentGPSCordinate: GpsLocationModel?

public func setSecretKey(_ key: String) {
    secretKey = key
}



public func setCurrentGPSCordinate(_ latitude: Double, longitude: Double) {
    currentGPSCordinate = GpsLocationModel(latitude: latitude, longitude: longitude)
}
