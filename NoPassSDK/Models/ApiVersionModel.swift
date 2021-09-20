//
//  ApiVersionModel.swift
//  Mapd
//
//  Created by Влад on 12/12/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

enum ApiVersionFlowType {
    case auth
    case registration
    case delete
    case encryption
    case update
    case restoring
}


class ApiVersionModel {
    
    let userAuthVersion: String
    let userRegistrationVersion: String
    let portalRegistrationVersion: String
    let userDeletionVersion: String
    let encryptionVersion: String
    let userUpdatingVersion: String
    let userRestoringVersion: String
    var serverDate: Date = Date()
     
    init() {
        self.userAuthVersion = AppConfig.API_USER_AUTHENTICATION_VERSION
        self.userRegistrationVersion = AppConfig.API_USER_REGISTRATION_VERSION
        self.portalRegistrationVersion = AppConfig.API_PORTAL_REGISTRATION_VERSION
        self.userDeletionVersion = AppConfig.API_USER_DELETION_VERSION
        self.encryptionVersion = AppConfig.API_ENCRYPTION_VERSION
        self.userUpdatingVersion = AppConfig.API_USER_UPDATE_VERSION
        self.userRestoringVersion = AppConfig.API_USER_RESTORING_VERSION
    }
    
    init(json: JSON) {
        self.userAuthVersion = json["apiUserAuthenticationVersion"].stringValue
        self.userRegistrationVersion = json["apiUserRegistrationVersion"].stringValue
        self.portalRegistrationVersion = json["apiPortalRegistrationVersion"].stringValue
        self.userDeletionVersion = json["apiUserDeletionVersion"].stringValue
        self.encryptionVersion = json["apiEncryptionVersion"].stringValue
        self.userUpdatingVersion = json["apiUserUpdatingVersion"].stringValue
        self.userRestoringVersion = json["ApiUserRestoringVersion"].stringValue
        self.serverDate = json["currentTime"].stringValue.dateFromString("yyyy-MM-dd'T'HH:mm:ss.SSSZ") ?? Date()
    }
    
    func getVersion(type: ApiVersionFlowType) -> String {
        switch type {
        case .auth:
            return self.userAuthVersion
        case .registration:
            return self.userRegistrationVersion
        case .delete:
            return self.userDeletionVersion
        case .encryption:
            return self.encryptionVersion
        case .update:
            return self.userUpdatingVersion
        case .restoring:
            return self.userRestoringVersion
        }
    }
             
}

extension ApiVersionModel {
    func toDictionary() -> [String: Any] {
        var result: [String: Any] = [:]
        result["apiUserAuthenticationVersion"] = self.userAuthVersion
        result["apiUserRegistrationVersion"] = self.userRegistrationVersion
        result["apiPortalRegistrationVersion"] = self.portalRegistrationVersion
        result["apiUserDeletionVersion"] = self.userDeletionVersion
        result["apiEncryptionVersion"] = self.encryptionVersion
        result["apiUserRestoringVersion"] = self.userRestoringVersion
        return result
    }
}

