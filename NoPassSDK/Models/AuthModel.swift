//
//  AuthModel.swift
//  Mapd
//
//  Created by Влад on 10/16/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

enum AuthType {
    case radius
    case portal
}

class AuthModel {
    
    // TODO - userCode
    
    var userCode: String
    var r: Int
    var username: String
    var pictureUpdatesInMinute: Int
    var portalId: String
    var portalUrl: String
    var authId: String
    var delay: Int
    var authType: AuthType?
    var clientName: String
    
    var customMessage: String?
    
    var secondsForUpdate: Int {
        return 60 / pictureUpdatesInMinute
    }
    
    init(json: JSON) {
        self.userCode = json["UserCode"].stringValue
        self.r = json["R"].intValue
        self.username = json["UserName"].stringValue
        self.pictureUpdatesInMinute = json["PictureUpdatesInMinute"].intValue
        self.portalId = json["PortalId"].stringValue
        self.portalUrl = json["PortalUrl"].stringValue
        self.authId = json["AuthId"].stringValue
        self.delay = json["Delay"].intValue
        
        if let flowValue = json["Workflow"].int, let workFlow = NoPassPushNotificationWorkflow.init(rawValue: flowValue)  {
            switch workFlow {
            case .RadiusUserAuthentication:
                self.authType = .radius
            case .UserAuthentication, .UserAuthenticationUpdateImage:
                self.authType = .portal
            default: self.authType = nil
            }
        }
        
        self.clientName = json["ClientName"].stringValue
        self.customMessage = json["CustomMessage"].string
    }
}
