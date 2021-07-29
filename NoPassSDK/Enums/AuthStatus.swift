//
//  AuthStatus.swift
//  NoPassSDK
//
//  Created by Vlad Krupnik on 13.01.2021.
//  Copyright © 2021 PSA. All rights reserved.
//

import Foundation


public enum AuthStatus {
    case accept
    case decline
    case declineFromOtherDevice
    
    public func toDictionaryForRN() -> Dictionary<AnyHashable, Any?> {
        switch self {
        case .accept:
            return [Constants.authStatusString: "accept"]
        case .decline:
            return [Constants.authStatusString: "decline"]
        case .declineFromOtherDevice:
            return [Constants.authStatusString: "declineFromOtherDevice"]
        }
    }
}

extension AuthStatus {
    struct Constants {
        static let authStatusString = "authStatus"
        static let logEventIdString = "logEventId"
    }
}
