
protocol RestorePortalServiceProtocol {
    
    func restore(serverUrl: String, userCode: String ,userId: String, portalId: String, portalName: String, pinCode: String, enabled2FaMethod: BiometricType, isScreenLock: Bool, comletion: ((UserMetaData?,Error?)->())?)
    
    func restoreConfirmation(serverUrl: String,sessionId: String, backupHash: String, portalName: String, comletion: ((UserMetaData?,Error?)->())?)
    
}
