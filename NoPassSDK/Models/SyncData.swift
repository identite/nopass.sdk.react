//
//  SyncData.swift
//  NoPassSDK
//
//  Created by Artsiom Shmaenkov on 10.03.2021.
//  Copyright © 2021 PSA. All rights reserved.
//

import Foundation

struct SyncData {
    var portalId: String
    var userCode: String
    var qrCode: String
    
    func toDictionary() -> [String: Any] {
        return [ "portalId": portalId,
                 "userCode": userCode,
                 "qrCode": qrCode
               ]
    }
}
