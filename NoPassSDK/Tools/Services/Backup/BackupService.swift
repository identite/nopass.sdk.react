import Foundation

class BackupService {
    var backupServerService: BackupServerServiceProtocol = BackupServerService(NetworkManager(), checkApiManger: CheckApiManger())
    
    static let shared: BackupService = BackupService()
    
    func createEmtyBackupData(pin: String) -> String {
        let pinHash = String(pin.prefix(4)).sha256()
        return encryptBackupData(items: [], pinHash: pinHash)
    }
    
    func makeBackup(pin: String, encryptedBackupData: String?, enabled2FaMethod: BiometricType, isScreenLock: Bool, completion: ((NopassError?, String?) -> Void)?) {
        var commonError: NopassError? = nil
        if pin.count != 6 {
            completion?(NopassError.backupWrongPin, nil)
            return
        }
        let portals = CoreDataManager.shared.getAccounts()
        
        if portals.isEmpty {
            completion?(NopassError.backupNonAccounts, nil)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        portals.forEach { (portal) in
            dispatchGroup.enter()
            self.backupServerService.backupRequest(portal: portal, deviceId: UserStorage.getPushToken() ?? "", pin: pin, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock) { (error) in
                if let error = error {
                    commonError = NopassError.custom(description: error.localizedDescription)
                }
                
                if let userCode = portal.userCode {
                    CoreDataManager.shared.update(userCode: userCode, isAccountBackup: true)
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            let encryptedData = self.makeBackupData(portals: portals, pin: pin, encryptedBackupData: encryptedBackupData)
            completion?(commonError,  encryptedData)
        }
    }
    
    func getDataFromBackup(pin: String, encrypted: String, completion: (([BackupAccountModel]?, NopassError?) -> Void)?) {
        if pin.count != 6 {
            completion?(nil ,NopassError.backupWrongPin)
            return
        }
        
        var backups: [BackupAccountModel] = []
        let pinHash = String(pin.prefix(4)).sha256()        
        
        if Data(base64Encoded: encrypted, options: .ignoreUnknownCharacters) == nil {
            completion?(nil,NopassError.restoreDamagedData)
        } else {
            backups = dencryptBackupData(encodedString: encrypted, pinHash: pinHash)
        }        
        
        if backups.isEmpty {
            completion?(nil,.restoreNonAccounts)
            return
        }
        
        let portals = CoreDataManager.shared.getAccounts()
        let portalsBackup = portals.map { BackupAccountModel(username: $0.userName ?? "",
                                                             userCode: $0.userCode ?? "" ,
                                                             portalid: $0.portalId ?? "",
                                                             portalName: $0.portalName ?? "",
                                                             apikey: $0.serverUrl ?? "",
                                                             pinHash: pinHash) }
        let diff = Array(Set(backups).subtracting(portalsBackup))
        completion?(diff,diff.isEmpty ? .restoreAccounts : nil)
        
    }
    
    func canDencryptBackupData(encodedString: String, pin: String) -> Bool {
        let cryptLib = CryptLib()
        let pinHash = String(pin.prefix(4)).sha256()
        guard let decryptedString = cryptLib.decryptCipherTextRandomIV(withCipherText: encodedString, key: pinHash) else {
            return false
        }
        
        let json = JSON(parseJSON: decryptedString)
        if let _ = json["items"].array {
            return true
        }
        
        return false
    }
    
    func clearBackupData() {
        let accounts = CoreDataManager.shared.getAccounts()
        accounts.forEach {
            if let userCode = $0.userCode {
                CoreDataManager.shared.update(userCode: userCode, isAccountBackup: false)
            }
        }
    }
    
    private func makeBackupData(portals: [Account], pin: String, encryptedBackupData: String?) -> String? {
        if pin.count <= 4 {return nil}
        let pinHash = String(pin.prefix(4)).sha256()
        
        var existingAccountModels = [BackupAccountModel]()
        if let encryptedBackupData = encryptedBackupData {
            existingAccountModels = dencryptBackupData(encodedString: encryptedBackupData, pinHash: pinHash)
        }
        
        var portalsBackup = portals.map { BackupAccountModel(username: $0.userName ?? "",
                                                             userCode: $0.userCode ?? "" ,
                                                             portalid: $0.portalId ?? "",
                                                             portalName: $0.portalName ?? "",
                                                             apikey: $0.serverUrl ?? "",
                                                             pinHash: pinHash) }
        portalsBackup.forEach {
            if let index = existingAccountModels.firstIndex(of: $0) {
                existingAccountModels.remove(at: index)
            }
        }
        portalsBackup += existingAccountModels
        
        return  encryptBackupData(items: portalsBackup, pinHash: pinHash)
    }
    
    private func encryptBackupData(items: [BackupAccountModel], pinHash: String) -> String {
        
        let dict = ["items": items.map { $0.toDictionary() }]
        let json = JSON(dict)
        
        let plainText = json.debugDescription
        
        let cryptLib = CryptLib()
        
        let cipherText = cryptLib.encryptPlainTextRandomIV(withPlainText: plainText, key: pinHash)
        
        return cipherText ?? ""
    }
    
    private func dencryptBackupData(encodedString: String, pinHash: String) -> [BackupAccountModel] {
        let cryptLib = CryptLib()
        guard let decryptedString = cryptLib.decryptCipherTextRandomIV(withCipherText: encodedString, key: pinHash) else { return [] }
        
        let json = JSON(parseJSON: decryptedString)
        let backups = json["items"].arrayValue.map{BackupAccountModel(json: $0)}
        
        return backups
    }
}
