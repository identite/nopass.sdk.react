//
//  Authentication.swift
//  Mapd
//
//  Created by Влад on 10/22/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

protocol AuthenticationServiceProtocol {
    func doVerifyDevice(_ auth: AuthModel, serverUrl: String, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((_ timestamp: String?,_ signedUrl: String?,_ delta: TimeInterval?,_ error: NSError?) -> Void)?)
    func authorize(signature: String, authId: String, answer: Bool, reason: String, timeStamp: String, serverUrl: String, secure: String, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion:NetworkManager.CompletionBlock?)
}
