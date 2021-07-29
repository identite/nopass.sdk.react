import UIKit

public struct NoPassAuthComparisonContent {
    public let digits: String
    public let image: UIImage?
    public let customMessage: String?
    
    public func toDictionary() -> Dictionary<String, Any?> {
        return ["digits" : digits,
                "pictureAsBase64" : convertImageToBase64String(img: image),
                "customMessage" : customMessage]
    }
    
    func convertImageToBase64String (img: UIImage?) -> String? {
        return img?.jpegData(compressionQuality: 1)?.base64EncodedString()
    }
}

public protocol NoPassAuthServiceDelegate: AnyObject {
    func onAuthDataChange(comparisonContent: NoPassAuthComparisonContent,authExparedDate: Date, nextUpdate: TimeInterval)
    func onRadiusAuthStart(clientName: String, account: NoPassAccount, authExparedDate: Date)
    func onAuthFinish(error: NopassError?, authStatus: AuthStatus)
}

public class NoPassAuthService {
    
    public static let shared = NoPassAuthService()
    private var authService: AuthenticationService = AuthenticationService()
    private var otpService: OtpService = OtpService()
    
    public weak var delegate: NoPassAuthServiceDelegate?
    
    private var authExparedDate: Date?
    var currentTimeStamp: String = ""
    var reason: String = ""
    var otp: String = ""
    var delta: Double = 0.0
    
    private var auth: AuthModel?
    private var portal: Account?
    private var isDeviceVerified = true
    private var executingSessions = [String : Bool]()

    var timer: Timer? = Timer()
    
    init() {}
    
    public func isHaveAuthSessionNow() -> Bool {
        return self.auth != nil
    }
    
    public func getAuthComparisonContent(data: [String:Any], userSeed: String) -> NoPassAuthComparisonContent? {
        
        var auth: AuthModel?
        
        if let stringJSON = JSON(data)["notification"]["data"].string  {
            let json = JSON(parseJSON: stringJSON)
            auth = AuthModel(json: json)
        } else if let stringJSON: String = data["gcm.notification.data"] as? String {
            let json = JSON.init(parseJSON: stringJSON)
            auth = AuthModel(json: json)
        }
        
        if let auth = auth {
            let (_,keyphrase) = otpService.getOTP(authId: auth.authId, userSeed: userSeed, authDelay: auth.delay)
            
            if let keyphrase = keyphrase {
                let image = getImage(keyphrase: keyphrase)
                let code  = otpService.getCode(keyphrase: keyphrase)
                return NoPassAuthComparisonContent(digits: code, image: image, customMessage: auth.customMessage)
            }
        }
        
        return nil
    }
    
    public func startAuthFlow(data: [AnyHashable:Any], enabled2FaMethod: BiometricType, isScreenLock: Bool) -> NoPassAuthModel? {
        if let stringJSON = JSON(data)["notification"]["data"].string  {
            let json = JSON(parseJSON: stringJSON)
            self.auth = AuthModel(json: json)
        } else if let stringJSON: String = data["gcm.notification.data"] as? String {
            let json = JSON.init(parseJSON: stringJSON)
            self.auth = AuthModel(json: json)
        }
        guard let auth = self.auth, let portal = CoreDataManager.shared.getAccount(userCode: auth.userCode)  else {
            onAuthFinish(error: .authAsyncTime, authStatus: .decline, auth: self.auth)
            return nil
        }
        self.portal = portal
        executingSessions[auth.authId] = false
        self.verifyDevice(auth, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
        
        return NoPassAuthModel(userName: auth.username, portalName: portal.portalName ?? "")
    }
    
    func authFlowWasFinishedOnOtherDevice(authId: String, isSuccess: Bool) {
        if executingSessions.keys.contains(authId) && isDeviceVerified {
            if executingSessions[authId] == false {
                if Date().timeIntervalSince1970 > authExparedDate?.timeIntervalSince1970 ?? 0 || timer == nil {
                    timeIsUP()
                } else {
                    onAuthFinish(error: nil, authStatus: isSuccess ? .accept : .declineFromOtherDevice, auth: auth)
                }
            }
        }
    }
    
    private func verifyDevice(_ auth: AuthModel, enabled2FaMethod: BiometricType, isScreenLock: Bool) {
        logMessage("")
        if self.authExparedDate != nil {
            startFlow()
            return
        } else if let time = UserStorage.getLastAuthDate() {
            self.authExparedDate = time.dateFromString()
            startFlow()
            return
        }
        
        //TODO: CHECK IT
        guard let serverUrl = portal?.serverUrl else { return }
        
        let serverName = serverUrl.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "/", with: "")
        
        //Workaround beacuse we can get UserAuthenticationResult push earlier than doVerifyDevice response
        isDeviceVerified = false
        authService.doVerifyDevice(auth, serverUrl: serverUrl, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock) { [weak self] (timestamp,
            signedUrl, delta,error) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.onAuthFinish(error: .custom(description: error.localizedDescription), authStatus: .decline, auth: auth)
                self?.isDeviceVerified = true
                return
            } else if let delta = delta {
                if abs(delta) > 15.0 {
                    strongSelf.onAuthFinish(error: .authAsyncTime, authStatus: .decline, auth: auth)
                    strongSelf.authorize(strongSelf.currentTimeStamp, auth: auth, serverUrl: serverUrl, reason: DeclineType.deviceDifferentTime.rawValue, isAccept: false, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
                    self?.isDeviceVerified = true
                    return
                }
            }
            
            guard let time = timestamp, let signedUrl = signedUrl else {
                self?.isDeviceVerified = true
                return
            }
            
            if !CryptoKeyService.isValidData(signedUrl: signedUrl, serverURL: serverName) {
                strongSelf.onAuthFinish(error: .invalidSignature, authStatus: .decline, auth: auth)
                self?.isDeviceVerified = true
                return
            }
            UserStorage.setLastAuthDate(value: time)
            self?.authExparedDate = time.dateFromString()
            self?.isDeviceVerified = true
            
            strongSelf.startFlow()
        }
    }
    
    
    private func startFlow() {
        guard let auth = auth, let userseed = portal?.userseed else {
            return
        }
        
        let (updateTime,bin) = otpService.getOTP(authId: auth.authId, userSeed: userseed, authDelay: auth.delay)
        guard let binary = bin else {
            return
        }
        
        self.currentTimeStamp = updateTime
        var keyphraseStr: String = binary.description
        
        if keyphraseStr.count > 6 {
            keyphraseStr = String(keyphraseStr.suffix(6))
        }
        self.otp = "\(auth.authId)#\(keyphraseStr)"
        self.updateTimer()
        
        let digits = otpService.getCode(keyphrase: binary)
        if auth.authType == AuthType.portal, let authExparedDate = authExparedDate {
            let content = NoPassAuthComparisonContent(digits: digits, image: self.getImage(keyphrase: binary), customMessage: auth.customMessage)
            delegate?.onAuthDataChange(comparisonContent: content, authExparedDate: authExparedDate, nextUpdate: TimeInterval(getNextUpdate()))
        } else if auth.authType == AuthType.radius, let authExparedDate = authExparedDate, let portal = portal {
            let account = NoPassAccount(userCode: portal.userCode ?? "",
                                        accountName: portal.userName ?? "",
                                        seed: portal.userseed ?? "",
                                        crearedDate: Date(),
                                        hex: portal.hex ?? "6D4C41",
                                        portalName: portal.portalName ?? "",
                                        portalId: portal.portalId ?? "",
                                        isAccountBackup: portal.isAccountBackup)
            delegate?.onRadiusAuthStart(clientName: auth.clientName, account: account, authExparedDate: authExparedDate)
        }
    }
    
    func getImage(keyphrase: Int) -> UIImage? {
        let imageName = getImageName(keyphrase: keyphrase)
        let image = ImageProvider.image(named: imageName)
        
        return image
    }
    
    func getImageName(keyphrase: Int) -> String {
        var imageCode = ((keyphrase / 1000) % 1000).description
        while imageCode.count <= 2 {
            imageCode.insert("0", at: imageCode.startIndex)
        }
        return "key_image_\(imageCode)"
    }
    
    func updateTimer() {
        logMessage("")
        
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(getNextUpdate()), target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    private func getNextUpdate() -> Int {
        var timerSeconds: Int = 30
        let delaySeconds = (auth!.delay) / 1000
        let tmpSec = Int(Int(Date().timeIntervalSince1970 + delta)) % 60
        
        
        let firstUpdate = 30 - delaySeconds
        
        let secondUpdate = 60 - delaySeconds
        
        
        if tmpSec >= firstUpdate && tmpSec < secondUpdate {
            timerSeconds = secondUpdate - tmpSec
        } else if tmpSec > secondUpdate {
            timerSeconds = 60 - tmpSec + firstUpdate
        } else if tmpSec < firstUpdate {
            timerSeconds = firstUpdate - tmpSec
        }
        return timerSeconds
    }
    
    @objc func timerAction() {
        logMessage("AuthExparedDate")
        if Date().timeIntervalSince1970 > authExparedDate?.timeIntervalSince1970 ?? 0 || timer == nil {
            timeIsUP()
            return
        }
        startFlow()
    }
    
    public func authorize(enabled2FaMethod: BiometricType = .null, isScreenLock: Bool) {
        guard let auth = self.auth, let serverUrl = portal?.serverUrl else { return }
        self.authorize(self.currentTimeStamp, auth: auth, serverUrl: serverUrl, reason: "", isAccept: true, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
    }
    
    public func decline(type: DeclineType, enabled2FaMethod: BiometricType, isScreenLock: Bool) {
        guard let auth = self.auth, let serverUrl = portal?.serverUrl else { return }
        self.authorize(self.currentTimeStamp, auth: auth, serverUrl: serverUrl, reason: type.rawValue, isAccept: false, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
    }
    
    private func authorize(_ time: String, auth: AuthModel, serverUrl: String, reason: String = "", isAccept: Bool = true, enabled2FaMethod: BiometricType = .null, isScreenLock: Bool) {
        executingSessions[auth.authId] = true
        if timer == nil {
            timeIsUP()
            return
        }
        
        guard let alias = portal?.alias ,let keyPair = KeyStorage.getKeyPair(key: alias), let serverUrl = portal?.serverUrl else {
            onAuthFinish(error: .invalidKeys, authStatus: .decline, auth: auth)
            return
        }
        
        guard let signature = CryptoKeyService.getSignature(self.otp, privateKey: keyPair.privateKey, publicKey: keyPair.publicKey) else {
            onAuthFinish(error: .authSignatureNotExist, authStatus: .decline, auth: auth)
            return
        }
        
        let secure = CryptoKeyService.getSecure(id: auth.authId, privateKey: keyPair.privateKey, publicKey: keyPair.publicKey)
        
        authService.authorize(signature: signature, authId: auth.authId, answer: isAccept, reason: reason, timeStamp: currentTimeStamp, serverUrl: serverUrl, secure: secure, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock) { [weak self] (result, error) in
            guard let strongSelf = self else { return }
            
            if !isAccept {
                strongSelf.onAuthFinish(error: nil, authStatus: .decline, auth: auth)
            } else if let error = error {
                strongSelf.onAuthFinish(error: .custom(description: error.localizedDescription), authStatus: .decline, auth: auth)
            } else {
                strongSelf.onAuthFinish(error: nil, authStatus: .accept, auth: auth)
            }
            
        }
    }
    
    
    private func timeIsUP() {
        onAuthFinish(error: .authSessionTimedOut, authStatus: .decline, auth: auth)
        finishAuthFlow()
    }
    
    private func onAuthFinish(error: NopassError?,authStatus: AuthStatus, auth: AuthModel?) {
        if let auth = auth, let portal = portal {
            CoreDataManager.shared.createAuthHistory(userCode: auth.userCode, userName: auth.username, portalUrl: auth.portalUrl, authDate: Date(), hex: portal.hex ?? "6D4C41", isSuccesAuth: authStatus == .accept)
        }
      
        self.delegate?.onAuthFinish(error: error, authStatus: authStatus)
        finishAuthFlow()
    }
    
    private func finishAuthFlow() {
        if let auth = auth {
            executingSessions.removeValue(forKey: auth.authId)
        }
        
        UserStorage.deleteLastAuthDate()
        self.timer?.invalidate()
        self.timer = nil
        authExparedDate = nil
        currentTimeStamp = ""
        reason = ""
        otp = ""
        delta = 0.0
        auth = nil
        portal = nil
        timer = nil
        NotificationCenter.default.removeObserver(self, name: .applicationWillEnterForeground, object: nil)
    }
}



