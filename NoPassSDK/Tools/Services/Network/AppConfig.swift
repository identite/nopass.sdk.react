//
//  ApiConfig.swift
//  Mapd
//
//  Created by Влад on 9/24/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation


enum REQUEST_TAG: Int {
    
    case confirmApp = 1
    case assignDevice
    case verifyDevice
    case keyApply
    //AUTH
    case authVarifyDevice
    case authorize
    
    //ACCOUNT
    case deleteInitialDevice
    case deleteConfirmation
    
    
    // VERSION
    case version
    
    //ACCOUNT UPDATE
    case updateInitialDevice
    case updateConfirmation
    
    //UserRestore
    case backup
    case backupConfirmation
    
    case restore
    case restoreConfirmation
    
    case syncUser
    case initSync
    case getSyncLinks
}


class AppConfig {
    
    static let PRIVACY_POLICY = "https://www.identite.us/privacy-policy"
    static let CONTACT_US_MAIL = "support@identite.us"
    static let ABOUT_US = "https://www.identite.us/"
    static let FAQ_WEB = "https://www.identite.us/frequentky-asked-questions"
    static let DEMO_WEB = "https://www.identite.us/how-to-use-nopass"
    static let TERMS_OF_USE = "https://www.identite.us/terms-and-conditions"
    
    static let APP_VERSION = "1.7.2"
    
    static let API_USER_AUTHENTICATION_VERSION = "3.0"
    static let API_USER_REGISTRATION_VERSION = "3.0"
    static let API_PORTAL_REGISTRATION_VERSION = "3.0"
    static let API_USER_DELETION_VERSION = "3.0"
    static let API_ENCRYPTION_VERSION = "2.0"
    static let API_USER_UPDATE_VERSION = "3.0"
    static let API_USER_RESTORING_VERSION = "3.0"
    
    
    
    
}
