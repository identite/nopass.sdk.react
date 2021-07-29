//
//  NoPassHistory.swift
//  NoPassSDK
//
//  Created by Vlad Krupnik on 15.01.2021.
//  Copyright © 2021 PSA. All rights reserved.
//

import Foundation

public struct NoPassHistory {
    public let userCode: String
    public let accountName: String
    public let portalName: String
    public let authDate: Date
    public let hex: String
    public let isSuccesAuth: Bool
    
    public func toDictionaryForRN() -> Dictionary<String, Any> {
        return ["userCode" : userCode,
                "accountName" : accountName,
                "portalName" : portalName,
                "authDate" : authDate.stringDate(timeZone: TimeZone(abbreviation: "UTC") ?? .current),
                "hex" : hex,
                "isSuccessAuth" : isSuccesAuth]
    }
}
