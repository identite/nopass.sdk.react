//
//  VerifyDeviceModel.swift
//  Mapd
//
//  Created by Vlad Krupnik on 17/01/2020.
//  Copyright © 2020 PSA. All rights reserved.
//

class VerifyDeviceModel {
    
    var sessionEndsInSeconds: Double = 120.0
    var isNeedConfirmationCode: Bool = true

    init() {
        self.sessionEndsInSeconds = 120.0
        self.isNeedConfirmationCode = true
    }
    
    init(json: JSON) {
        let time = json["sessionEndsInSeconds"].doubleValue
        self.sessionEndsInSeconds = time < 1.0 ? 120.0 : time
        self.isNeedConfirmationCode = json["isNeedConfirmationCode"].boolValue
    }
}
