//
//  RegistrationServiceProtocol.swift
//  Mapd
//
//  Created by Влад on 10/7/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

protocol RegistrationServiceProtocol {
    func doConfirmApp(_ user: UserMetaData, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: NetworkManager.CompletionBlock?)
    func doAssigneDevice(_ deviceId: String, otp: String, serverUrl: String,completion: NetworkManager.CompletionBlock?)
    func doVerifyDevice(_ user: UserMetaData, r: Int, token: String,completion: NetworkManager.CompletionBlock?)
    func doKeyApply(_ otp: String, encodedPublicKey: String, signature: String, data: [String: Any], r2: Int, serverUrl: String,timeoutInterval: Double,secure: String, completion: ((String?,String?,Error?)->())?)
}
