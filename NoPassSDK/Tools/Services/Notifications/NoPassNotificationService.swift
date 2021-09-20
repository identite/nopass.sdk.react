import Foundation

public enum NoPassPushNotificationWorkflow: Int {
    case UserAuthentication = 0
    case UserAuthenticationUpdateImage = 1
    case UserRegistration = 2
    case UserDeletion = 3
    case UserUpdating = 4
    //    case UserDeletionDuringRestore = 5
    case RadiusUserAuthentication = 6
    case AuthenticationResult = 7
    case AccountSynchronization = 10
    
    case unowned
    
    public func notificationName() -> String {
        switch self {
        case .UserAuthentication:
            return "NoPassUserAuthentication"
        case .UserAuthenticationUpdateImage:
            return "NoPassUserAuthenticationUpdateImage"
        case .UserRegistration:
            return "NoPassUserRegistration"
        case .UserDeletion:
            return "NoPassUserDeletion"
        case .UserUpdating:
            return "NoPassUserUpdating"
        case .RadiusUserAuthentication:
            return "NoPassRadiusUserAuthentication"
        case .AuthenticationResult:
            return "NoPassAuthenticationResult"
        case .AccountSynchronization:
            return "NoPassAccountSynchronization"
        case .unowned:
            return "NoPassUnowned"
        }
    }
}

public class NoPassNotificationService {
    
    public static let shared = NoPassNotificationService()
    
    public func getNotificationType(data: [AnyHashable
        : Any] ) -> NoPassPushNotificationWorkflow {
        
        if let flow = data["Workflow"] as? String, let flowValue = Int(flow), let workFlow = NoPassPushNotificationWorkflow.init(rawValue: flowValue)  {
            return workFlow
        } else if let flowValue = JSON(parseJSON: JSON(data)["notification"]["data"].stringValue)["Workflow"].int, let workFlow = NoPassPushNotificationWorkflow.init(rawValue: flowValue) {
            return workFlow
        } else if let stringJSON: String = data["gcm.notification.data"] as? String {
            let json = JSON.init(parseJSON: stringJSON)
            if let flowValue = json["Workflow"].int, let workFlow = NoPassPushNotificationWorkflow.init(rawValue: flowValue)  {
                return workFlow
            }
        }
        
        return .unowned
    }
    
    public func setRegistrationToken(token: String) {
        UserStorage.setPushToken(value: token)
    }
    
    public func getRegistrationToken() -> String? {
        UserStorage.getPushToken()
    }
    
    public func passNotification(data: [AnyHashable
        : Any]?, enabled2FaMethod: BiometricType, isScreenLock: Bool) {
        guard let data = data else {
            return
        }
        
        switch getNotificationType(data: data) {
        case .UserRegistration:
            NotificationCenter.default.post(name: .didReceiveRegistationData, object: self, userInfo: data)
        case .UserDeletion:
            if let _ = data["UserName"] as? String, let _ = data["PortalId"] as? String, let sessionId = data["SessionId"] as? String {
                let userCode = data["UserCode"] as? String ?? ""
                if let portal = CoreDataManager.shared.getAccount(userCode: userCode) {
                    let account = NoPassAccount(userCode: portal.userCode ?? "",
                                                accountName: portal.userName ?? "",
                                                seed: portal.userseed ?? "",
                                                crearedDate: Date(),
                                                hex: portal.hex ?? "6D4C41",
                                                portalName: portal.portalName ?? "",
                                                portalId: portal.portalId ?? "",
                                                isAccountBackup: portal.isAccountBackup)
                    
                    NoPassRemoveAccountService.shared.deleteDevice(account: account, session: sessionId, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock) { (error) in
                        if let error = error {
                            logMessage(error.localizedDescription)
                        } else {
                            logMessage("✅ Account delete succesfuly")
                        }
                    }   
                }
            }
            
        case .UserUpdating:
            guard let portalID = data["PortalId"] as? String, let jsonString = data["Updates"] as? String else {
                return
            }
            
            let portalUpdate = AccountUpdatesModel(json: JSON(parseJSON: jsonString))
            
            let userCode = data["UserCode"] as? String ?? ""
            
            if let portal = CoreDataManager.shared.getAccount(userCode: userCode) {
                AccountUpdateService.shared.setAccountUpdatesModel(accountUpdatesModel: portalUpdate)
                AccountUpdateService.shared.updateDevice(portal: portal, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
            }
            
        case .AccountSynchronization:
            if let confirmId = data["ConfirmId"] as? String {
                NoPassSynchronisationService.shared.finishAccountSynchronisation(confirmId: confirmId, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
            }
        case .AuthenticationResult:
            if let isSuccessStr = data["IsSuccess"] as? String, let isSuccess = Bool(isSuccessStr), let authId = data["AuthId"] as? String {
                NoPassAuthService.shared.authFlowWasFinishedOnOtherDevice(authId: authId, isSuccess: isSuccess)
            }            
        default: return
        }
        
    }
}
