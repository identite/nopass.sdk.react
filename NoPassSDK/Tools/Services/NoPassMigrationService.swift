//
//  NoPassMigrationService.swift
//  NoPassSDK
//
//  Created by Vlad Krupnik on 22.01.2021.
//  Copyright © 2021 PSA. All rights reserved.
//

public class NoPassMigrationService {
    
    public static var shared = NoPassMigrationService()
    
    public func saveAccount(userCode: String, userName: String, portalName: String, userseed: String, portalUrl: String, serverUrl: String, alias: String, createdDate: Date, hex: String) {
        CoreDataManager.shared.createAccount(userCode: userCode,
                                             userName: userName,
                                             portalId: portalName,
                                             portalName: portalUrl.removeHostName(),
                                             userseed: userseed,
                                             portalUrl: portalUrl,
                                             serverUrl: serverUrl,
                                             alias: alias,
                                             createdDate: createdDate,
                                             hex: hex)
    }
    
    
    public func saveAuthHistory(userCode: String, userName: String, portalUrl: String, authDate: Date, hex: String, isSuccesAuth: Bool)  {
        CoreDataManager.shared.createAuthHistory(userCode: userCode, userName: userName, portalUrl: portalUrl, authDate: authDate, hex: hex, isSuccesAuth: isSuccesAuth)
        
    }
    
}
