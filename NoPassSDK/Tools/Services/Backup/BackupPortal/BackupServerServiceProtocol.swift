//
//  BackupPortalServiceProtocol.swift
//  Mapd
//
//  Created by Vlad Krupnik on 09/03/2020.
//  Copyright © 2020 PSA. All rights reserved.
//

import Foundation

protocol BackupServerServiceProtocol {
   func backupRequest(portal: Account, deviceId: String, pin: String, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((Error?)->())?)
   func backupConfirmation(portal: Account, sessionId: String, pin: String, completion: ((Error?)->())?)
}
