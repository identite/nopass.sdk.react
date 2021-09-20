import Foundation

public protocol NoPassRegistrationServiceDelegate: AnyObject {
    func registration(account: NoPassAccount?, error: NopassError?)
    func registrationCode(code: String,isNeedConfirmationCode: Bool)
}

extension NoPassRegistrationServiceDelegate {
    func registrationCode(code: String) {}
}

public class NoPassRegistrationService {
    
    public static let shared = NoPassRegistrationService()
    
    private var registration: RegistrationService = RegistrationService()
    
    private var user: UserMetaData?
    private var verify: VerifyDeviceModel = VerifyDeviceModel()
    private (set) var keyPair: (privateKey: PrivateKey, publicKey: PublicKey)?
    
    public weak var delegate: NoPassRegistrationServiceDelegate?
    
    init() {
        
    }
    
    private func reset() {
        user = nil
        verify = VerifyDeviceModel()
        keyPair = nil
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveAssigeDeviceData(_:)), name: .didReceiveRegistationData, object: nil)
    }
    
    public func startRegistration(result: String, enabled2FaMethod: BiometricType, isScreenLock: Bool) {
        guard let userDict = URLParser.getDecodedParam(string: result) else {
            self.delegate?.registration(account: nil, error: .invalidQRCode)
            return
        }
        
        let user = UserMetaData(dict: userDict)
        appConfirm(user: user, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
    }
    
    func appConfirm(user: UserMetaData, enabled2FaMethod: BiometricType, isScreenLock: Bool) {
        reset()
        self.user = user
        registration.doConfirmApp(user, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock) { [weak self] (result, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.delegate?.registration(account: nil, error: .custom(description: error.localizedDescription))
                return
            } else if let signedUrl = result as? String, let pushToken = UserStorage.getPushToken() {
                if !CryptoKeyService.isValidData(signedUrl: signedUrl, serverURL: user.serverName) {
                    strongSelf.delegate?.registration(account: nil, error: .invalidSignature)
                    return
                }
                strongSelf.assignDevice(pushToken, otp: user.otp, serverUrl: user.serverUrl)
            }
        }
    }
    
    private func assignDevice(_ deviceId: String, otp: String, serverUrl: String) {
        registration.doAssigneDevice(deviceId, otp: otp, serverUrl: serverUrl) { [weak self] (result, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.delegate?.registration(account: nil, error: .custom(description: error.localizedDescription))
            }
        }
    }
    
    @objc func onDidReceiveAssigeDeviceData(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self, name: .didReceiveRegistationData, object: nil)
        guard let data = notification.userInfo as? [String: Any], let r1Str = data["R1"] as? String, let r1: Int = Int.init(r1Str) else { return }
        self.user?.r1 = r1
        verifyDevice(self.user?.r1 ?? 0)
    }
    
    private func verifyDevice(_ r1: Int) {
        guard let user = user, let token = UserStorage.getPushToken() else { return }
        registration.doVerifyDevice(user, r: r1, token: token) { [weak self] (result, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.delegate?.registration(account: nil, error: .custom(description: error.localizedDescription))
                return
            }
            
            if let verify = result as? VerifyDeviceModel {
                strongSelf.verify = verify
            }
            
            strongSelf.generateKeyPair()
            
        }
    }
        
    private func generateKeyPair() {
        self.keyPair = CryptoKeyService.generateRSAKeyPair()
        
        guard let publicKey = keyPair?.publicKey, let ecodedPublicKey = CryptoKeyService.getEncodedPublicKey(publicKey: publicKey)  else {
            self.delegate?.registration(account: nil, error: .invalidKeys)
            return
        }
        
        let r2 = Int.random(in: 10000000 ... 99999999)
        self.keyApply(ecodedPublicKey, r2: r2)
    }
    
    
    private func keyApply(_ encodedPublicKey: String, r2: Int) {
        
        guard let token = UserStorage.getPushToken() else {
            self.delegate?.registration(account: nil, error: .missingPushToken)
            return
        }
        
        guard let user = user, let privateKey = keyPair?.privateKey else {
            self.delegate?.registration(account: nil, error: .invalidKeys)
            return
        }
        
        let data: [String: Any] = ["deviceId": token,
                                   "portalId": user.portalid,
                                   "portalUrl": user.portalUrl,
                                   "r": ((user.r1 ?? 0) + 1),
                                   "userName": user.username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""]                
        
        guard let signJSON = data.json, let signature = CryptoKeyService.getSignature(signJSON.cleare(), privateKey: privateKey, publicKey: self.keyPair?.publicKey) else {
            self.delegate?.registration(account: nil, error: .invalidSignature)
            return
        }        
        
        self.delegate?.registrationCode(code: r2.description,isNeedConfirmationCode: verify.isNeedConfirmationCode)
        
        
        let secure = CryptoKeyService.getSecure(id: user.otp, privateKey: privateKey, publicKey: self.keyPair?.publicKey)
        
        registration.doKeyApply(user.otp, encodedPublicKey: encodedPublicKey, signature: signature, data: data, r2: r2, serverUrl: user.serverUrl, timeoutInterval: verify.sessionEndsInSeconds + 2.0, secure: secure) { [weak self] (userCode, encryptedData, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.delegate?.registration(account: nil, error: .custom(description: error.localizedDescription))
                return
            } else if let encryptedData = encryptedData {
                strongSelf.confirmRegistration(encryptedData: encryptedData)
            }
        }
    }
            
    func confirmRegistration(encryptedData: String) {
        
        guard let user = user, let privateKey = keyPair?.privateKey, let publicKey = keyPair?.publicKey else { return }
        
        registration.doConfirmRegistration(otp: user.otp, serverUrl: user.serverUrl) { [weak self]  (userCode, isSucces , error) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.delegate?.registration(account: nil, error: .custom(description: error.localizedDescription))
                return
            } else if let userCode = userCode {
                self?.user?.userCode = userCode
                let alias = "\(userCode)+\(user.portalid)"
                KeyStorage.saveKeyPair(key: alias, publicKey: publicKey, privateKey: privateKey)
                let hex = ColorsService.getHex(number: Int.random(in: 0...20))
                /*
                 TODO: Need to fix. Sometimes we can't decrypt userseed, and it is the reason of several bugs (User deletion, backup data).
                 Some solutions:
                 1) Find the reason of a failed decryption
                 2) If we have an empty userseed. Show popup with error to register user again
                */
                let userseed = CryptoKeyService.decryptedMessage(encryptedData, privateKey: privateKey)
                // add portalName for old accounts
                let portalName = user.portalName.isEmpty == false ? user.portalName : user.portalUrl.removeHostName()
                CoreDataManager.shared.createAccount(userCode: userCode,
                                                     userName: user.username,
                                                     portalId: user.portalid,
                                                     portalName: portalName,
                                                     userseed: userseed,
                                                     portalUrl: user.portalUrl,
                                                     serverUrl: user.serverUrl,
                                                     alias: alias,
                                                     createdDate: Date(),
                                                     hex: hex)
                                
                let account = NoPassAccount(userCode: userCode,
                                            accountName: user.username,
                                            seed: userseed,
                                            crearedDate: Date(),
                                            hex: hex,
                                            portalName: portalName,
                                            portalId: user.portalid,
                                            isAccountBackup: false)
                
                strongSelf.delegate?.registration(account: account, error: nil)
            }
        }
    }    
}

public extension Notification.Name {
    static let didReceiveAssigeDeviceData = Notification.Name("didReceiveAssigeDeviceData")
    static let applicationWillEnterForeground = Notification.Name("applicationWillEnterForeground")
    private static let onAccountsChange = Notification.Name("onAccountsChange")
    
    
    static let didReceiveRegistationData = Notification.Name("didReceiveRegistationData")
}

public enum NopassError : Error {
    case custom(description: String)
    case invalidRegistrationData
    case invalidSignature
    case invalidKeys
    case missingPushToken
    
    case authIncorrect
    case authAsyncTime
    case authSignatureNotExist
    case authSessionTimedOut
    
    
    case backupWrongPin
    case backupNonAccounts
    
    case restoreDamagedData
    case restoreNonAccounts
    case restoreAccounts
    
    case invalidSynchronisationData
    case invalidQRCode
}


extension NopassError {
    public var errorDescription: String {
        switch self {
        case .custom(let description):
            return description
        case .invalidRegistrationData:
            return "Invalid registration data".localized()
        case .invalidSignature:
            return "Invalid signature".localized()
        case .invalidKeys:
            return "Invalid keys".localized()
        case .missingPushToken:
            return "Missing push token".localized()
        case .authAsyncTime:
            return "A big asynchronization between times on server and mobile device. Please set the correct time and try again".localized()
        case .authSignatureNotExist:
            return ""
        case .authIncorrect:
            return "Incorrect auth".localized()
        case .authSessionTimedOut:
            return "Authentication session timed out. Please try again.".localized()
        case .backupWrongPin:
            return "Pin must contain 6-digits".localized()
        case .backupNonAccounts:
            return "You don't have accounts".localized()
        case .restoreDamagedData:
            return "Your backup file is damaged. Unable to restore accounts.".localized()
        case .restoreNonAccounts:
            return "You don't have accounts".localized()
        case .restoreAccounts:
            return "Your accounts have already restored.".localized()
        case .invalidSynchronisationData:
            return "Invalid synchronisation data".localized()
        case .invalidQRCode:
            return "Invalid QR code".localized()
        }
    }
}
