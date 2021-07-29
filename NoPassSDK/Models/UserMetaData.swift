//
//  UserMetaData.swift
//  Mapd
//
//  Created by Влад on 9/23/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation
 
struct UserMetaData {
  
    var userCode: String
    
    let username: String
    let otp: String
    let portalid: String
    let portalName: String
    let portalUrl: String
    let serverUrl: String
    let confirmid: String
    var r1: Int?
    var syncId: String?
    var clientIp: String?
    
    var serverName: String {
        return serverUrl.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "/", with: "")
    }
    
    init(dict: [String : String]) {
        self.userCode = dict["userCode"] ?? ""
        self.username = dict["username"] ?? ""
        self.otp = dict["otp"] ?? ""
        self.portalid = dict["portalid"] ?? ""
        self.portalUrl = dict["portalurl"] ?? ""
        self.portalName = dict["portalname"] ?? ""
        self.serverUrl = dict["serverurl"] ?? ""
        self.confirmid = dict["confirmid"] ?? ""
        self.syncId = dict["syncId"]
        self.clientIp = dict["clientIp"]
    }
    
    init(json: JSON, portalName: String, serverUrl: String) {
        self.userCode = json["userCode"].stringValue
        self.username = json["userName"].stringValue
        self.otp = json["otp"].stringValue
        self.portalid = json["portalId"].stringValue
        self.portalUrl = json["portalUrl"].stringValue
        self.serverUrl = serverUrl
        self.confirmid = json["confirmId"].stringValue
        self.portalName = portalName
    }
}

extension UserMetaData {
    func toDictionary() -> [String: Any] {
        var result: [String: Any] = [:]
        
        result["username"] = self.username
        result["otp"] = self.otp
        result["portalid"] = self.portalid
        result["portalurl"] = self.portalUrl
        result["portalname"] = self.portalName
        
        return result
    }
}

