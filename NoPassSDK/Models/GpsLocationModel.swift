//
//  GpsLocationModel.swift
//  Mapd
//
//  Created by Vlad Krupnik on 07/04/2020.
//  Copyright © 2020 PSA. All rights reserved.
//

import Foundation

struct GpsLocationModel {
    let latitude: Double
    let longitude: Double
}


extension GpsLocationModel {
    func toDictionary() -> [String: Any] {
        var result: [String: Any] = [:]
        result["Latitude"] = self.latitude
        result["Longitude"] = self.longitude
        return result
    }
}
