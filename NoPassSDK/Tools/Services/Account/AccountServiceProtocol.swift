import Foundation

protocol AccountServiceProtocol {
    func deleteInitialDevice(_ userId: String, userCode: String, portalId: String, deviceId: String, serverUrl: String, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((_ sessionId: String?, _ encryptedData: String?,_ signedUrl: String? ,_ error: NSError?) -> Void)?)
    func deleteConfirmation(_ encryptedData: String, sessionId: String,secure: String,serverUrl: String, completion: NetworkManager.CompletionBlock?)
    
//    func updateInitialDevice(_ userId: String, userCode: String, portalId: String, deviceId: String,serverUrl: String, accountUpdates : AccountUpdatesModel, completion: ((String? ,String?, String?, Bool, NSError?) -> Void)?)
//    
//    func updateConfirmation(_ encryptedData: String, sessionId: String, serverUrl: String, completion: NetworkManager.CompletionBlock?)
    
    
}
