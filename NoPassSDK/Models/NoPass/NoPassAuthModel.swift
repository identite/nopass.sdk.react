//
//  NoPassAuthModel.swift
//  NoPassSDK
//
//  Created by Artsiom Shmaenkov on 05.03.2021.
//  Copyright © 2021 PSA. All rights reserved.
//

import Foundation

public struct NoPassAuthModel {
    public let userName: String
    public let portalName: String
    
    public func toDictionaryForRN() -> Dictionary<String, String> {
        return [ "userName" : userName,
                 "portalName" : portalName]
    }
}
