import Foundation

public protocol RestoreFlowDelegate: class {
    func restoreDidFinish(error: NopassError?)
    func accountDidRestore(account: NoPassAccount?)
}

class RestoreFlowManager {
    static let shared = RestoreFlowManager()
    private let restore: RestorePortalServiceProtocol = RestorePortalService()
    var backups: [BackupAccountModel] = []
    var error: NopassError?
    var pin: String = ""
    var isScreenLock = false
    var enabled2FaMethod = BiometricType.null
    weak var delegate: RestoreFlowDelegate?
    
    func startRestoreFlow(backups: [BackupAccountModel], pin: String, delegate: RestoreFlowDelegate?, enabled2FaMethod: BiometricType, isScreenLock: Bool) {
        self.pin = pin
        self.isScreenLock = isScreenLock
        self.enabled2FaMethod = enabled2FaMethod
        self.backups = backups
        self.delegate = delegate
        if let backup = backups.first {
            self.restore(backup: backup, pin: pin)
        } else {
            self.delegate?.restoreDidFinish(error: error)
        }
    }
    
    func restore(backup: BackupAccountModel, pin: String) {
        restore.restore(serverUrl: backup.apikey, userCode: backup.userCode, userId: backup.username, portalId: backup.portalid, portalName: backup.portalName, pinCode: pin, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock) { [unowned self] (user, error) in
            if let error = error {
                self.backups.removeFirst()
                self.error = NopassError.custom(description: error.localizedDescription)
                self.startRestoreFlow(backups: self.backups, pin: pin, delegate: delegate, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
            } else if let user = user {
                NoPassRegistrationService.shared.delegate = self
                NoPassRegistrationService.shared.appConfirm(user: user, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
            }
        }
    }
}

extension RestoreFlowManager : NoPassRegistrationServiceDelegate {
    func registrationCode(code: String, isNeedConfirmationCode: Bool) {  }
        
    func registration(account: NoPassAccount?, error: NopassError?) {
        self.backups.removeFirst()
        self.error = error
        self.startRestoreFlow(backups: self.backups, pin: pin, delegate: delegate, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
        delegate?.accountDidRestore(account: account)
    }
}
