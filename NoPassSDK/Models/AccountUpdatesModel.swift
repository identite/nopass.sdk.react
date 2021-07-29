//
//  PotalUpdatesModel.swift
//  Mapd
//
//  Created by Vlad Krupnik on 27/01/2020.
//  Copyright © 2020 PSA. All rights reserved.
//

import Foundation


final class UpdatesModel {
    var newValue: String = ""
    var forbiddenStore: Bool
    
    init(json: JSON) {
        self.newValue = json["NewValue"].stringValue
        self.forbiddenStore = json["forbiddenStore"].boolValue
    }
    
    
    func toDictionary() -> [String: Any] {
        var result: [String: Any] = [:]
        result["newValue"] = self.newValue
        result["forbiddenStore"] = self.forbiddenStore
        return result
    }
    
}


final class AccountUpdatesModel {
    
    var login: UpdatesModel
    
    init(json: JSON) {
        self.login = UpdatesModel(json: json["Login"])
    }
    
    func toDictionary() -> [String: Any] {
        var result: [String: Any] = [:]
        result["Login"] = self.login.toDictionary()
        return result
    }
}

