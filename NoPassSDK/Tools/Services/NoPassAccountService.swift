import Foundation
import UIKit

public class NoPassAccountService {
    
    public static let shared = NoPassAccountService()
    private let restore: RestorePortalServiceProtocol = RestorePortalService()
    private let registration: RegistrationService = RegistrationService()
    public var onAccountsChange:   (() -> ())?
    init() {}
    
    public func fetchAccounts() -> [NoPassAccount] {
        let accounts = CoreDataManager.shared.getAccounts()
        return accounts.map{NoPassAccount(userCode: $0.userCode ?? "",
                                          accountName: $0.userName ?? "",
                                          seed: $0.userseed ?? "",
                                          crearedDate: Date(),
                                          hex: $0.hex ?? "6D4C41",
                                          portalName: $0.portalName ?? "",
                                          portalId: $0.portalId ?? "",
                                          isAccountBackup: $0.isAccountBackup)}
    }
    
    public func fetchAccount(userCode: String) -> NoPassAccount? {
        guard let account = CoreDataManager.shared.getAccount(userCode: userCode) else {
            return nil
        }
        
        return NoPassAccount(userCode: account.userCode ?? "",
                             accountName: account.userName ?? "",
                             seed: account.userseed ?? "",
                             crearedDate: account.createdDate ?? Date(),
                             hex: account.hex ?? "",
                             portalName: account.portalName ?? "",
                             portalId: account.portalId ?? "",
                             isAccountBackup: account.isAccountBackup)
    }
    
    
    public func fetchHisory() -> [NoPassHistory] {
        let accounts = CoreDataManager.shared.getHistory()
        return accounts.map{NoPassHistory(userCode: $0.userCode ?? "", accountName: $0.userName ?? "", portalName: $0.portalUrl ?? "", authDate: $0.authDate ?? Date(), hex: $0.hex ?? "", isSuccesAuth: $0.isSuccesAuth)}
    }
    
    public func removeAccount(account: NoPassAccount, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((_ error: NSError?) -> Void)?) {
        guard let token = UserStorage.getPushToken() else {
            return
        }
        NoPassRemoveAccountService.shared.deleteDevice(account: account, session: token, isNeedUpdateBackup: false, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock) { (error) in
            completion?(error)
        }
    }
    
    func removeAccountFromPush(account: NoPassAccount, session: String, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((_ error: NSError?) -> Void)?) {
        NoPassRemoveAccountService.shared.deleteDevice(account: account, session: session, isNeedUpdateBackup: false, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock) { (error) in
            completion?(error)
        }
    }
    
    public func clearBackupData() {
        BackupService.shared.clearBackupData()
    }
    
    public func emptymptyBackupData(pin: String) -> String {
        return BackupService.shared.createEmtyBackupData(pin: pin)
    }
    
    public func isCanDecodeBackupFile(encodedString: String, pin: String) -> Bool {
        BackupService.shared.canDencryptBackupData(encodedString: encodedString, pin: pin)
    }
    
    public func backupAccounts(pin: String, encryptedBackupData: String?, enabled2FaMethod: BiometricType, isSreenLock: Bool, completion: ((NopassError?, String?) -> Void)?) {
        BackupService.shared.makeBackup(pin: pin, encryptedBackupData: encryptedBackupData, enabled2FaMethod: enabled2FaMethod, isScreenLock: isSreenLock, completion: completion)
    }
    
    public func restoreAccounts(backupData: String, pin: String, delegate: RestoreFlowDelegate?, enabled2FaMethod: BiometricType, isScreenLock: Bool, restoreDidStart: ((Int, NopassError?) -> Void)?) {
        BackupService.shared.getDataFromBackup(pin: pin, encrypted: backupData) { (accounts, error) in
            if let accounts = accounts {
                restoreDidStart?(accounts.count, nil)
                RestoreFlowManager.shared.startRestoreFlow(backups: accounts, pin: pin, delegate: delegate, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
            } else {
                restoreDidStart?(0, error)
            }
        }
    }
    
    public func subscribe() {
        CoreDataManager.shared.subscribe()
        CoreDataManager.shared.onAccountsChange = { [unowned self] in
            self.onAccountsChange?()
        }
    }
}
