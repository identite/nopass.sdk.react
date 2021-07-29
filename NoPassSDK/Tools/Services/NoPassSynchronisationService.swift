//
//  NoPassSynchronisationService.swift
//  NoPassSDK
//
//  Created by Artsiom Shmaenkov on 12.03.2021.
//  Copyright © 2021 PSA. All rights reserved.
//

import Foundation

public protocol NoPassSynchronisationServiceDelegate: AnyObject {
    func synchronisationDidFinish()
    func syncRegistrationCode(code: String, isNeedConfirmationCode: Bool)
    func accountWasSynchronised(account: NoPassAccount?, error: NopassError?)
    func synchronisationDidFail(error: NopassError)
}

public class NoPassSynchronisationService {

    public static let shared = NoPassSynchronisationService()    
    public weak var delegate: NoPassSynchronisationServiceDelegate?
    
    private var isSyncRegistration: Bool
    private var user: UserMetaData?
    private var dataForSync: [String] = []
    private var enabled2FaMethod: BiometricType?
    private var isScreenLock: Bool?
        
    private var registrationAPIService: RegistrationService
    private var registrationService: NoPassRegistrationService
    
    init() {
        isSyncRegistration = false
        registrationAPIService = RegistrationService()
        registrationService = NoPassRegistrationService.shared
        registrationService.delegate = self
    }
    
    public func startSyncAccount(result: String, enabled2FaMethod: BiometricType, isScreenLock: Bool) {
        guard let userDict = URLParser.getDecodedParam(string: result) else {
            delegate?.synchronisationDidFail(error: .invalidSynchronisationData)
            return
        }
        
        user = UserMetaData(dict: userDict)
        if let existUser = CoreDataManager.shared.getAccount(userName: user!.username, portalId: user!.portalid) {
            if let userCode = existUser.userCode {
                user?.userCode = userCode
            }
            syncAccounts()
        } else {
            isSyncRegistration = false
            registrationService.appConfirm(user: user!, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
        }
    }
    
    public func finishAccountSynchronisation(confirmId: String, enabled2FaMethod: BiometricType, isScreenLock: Bool) {
        guard let token = UserStorage.getPushToken() else {
            delegate?.synchronisationDidFail(error: .missingPushToken)
            return
        }
        
        guard let user = user, let syncId = user.syncId, let keyPair = registrationService.keyPair else {
            delegate?.synchronisationDidFail(error: .invalidSynchronisationData)
            return
        }
        
        let secure = CryptoKeyService.getSecure(id: syncId, privateKey: keyPair.privateKey, publicKey: keyPair.publicKey)
        
        registrationAPIService.doGetSyncLinks(serverUrl: user.serverUrl,
                                              syncId: syncId,
                                              confirmId: confirmId,
                                              deviceId: token,
                                              secure: secure) { [weak self] (result, error) in
            if let error = error {
                self?.delegate?.synchronisationDidFail(error: .custom(description: error.localizedDescription))
                return
            }
            
            if let result = result as? [String] {
                self?.dataForSync = result
                if let userMeta = self?.userMetaForSynchronisation() {
                    self?.isSyncRegistration = true
                    self?.isScreenLock = isScreenLock
                    self?.enabled2FaMethod = enabled2FaMethod
                    self?.registrationService.appConfirm(user: userMeta, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
                    self?.dataForSync.removeFirst()
                } else {
                    self?.delegate?.synchronisationDidFinish()
                }
            } else {
                self?.delegate?.synchronisationDidFinish()
            }
        }
    }
    
    func syncAccounts() {
        guard let pushToken = UserStorage.getPushToken(), let clientIp = user?.clientIp else {
            delegate?.synchronisationDidFail(error: .invalidSynchronisationData)
            return
        }
        
        let dispatchGroup = DispatchGroup()
        let accountArray = CoreDataManager.shared.getAccounts()
        var syncDataArray = [SyncData]()
        accountArray.forEach { (account) in
            if let serverUrl = account.serverUrl, let portalId = account.portalId, let userCode = account.userCode, userCode != user?.userCode, let alias = account.alias {
                dispatchGroup.enter()
                let currentDate = Date()
                let secure = self.getSecure(alias: alias,
                                            strValue: currentDate.stringDate(format: "ddMMyyyyHHmmss", timeZone: TimeZone(abbreviation: "UTC") ?? .current))
                registrationAPIService.doSyncUser(serverUrl: serverUrl,
                                                  portalId: portalId,
                                                  userCode: userCode,
                                                  deviceId: pushToken,
                                                  clientIp: clientIp,
                                                  date: DateFormatter.iso8601DateFormatter.string(from: currentDate),
                                                  secure: secure) { [weak self] (result, error) in
                    if let error = error {
                        self?.delegate?.accountWasSynchronised(account: nil, error: .custom(description: error.localizedDescription))
                    } else {
                        if let portalId = account.portalId, let userCode = account.userCode,  let qrCode = result as? String {
                            syncDataArray.append(SyncData(portalId: portalId, userCode: userCode, qrCode: qrCode))
                        } else {
                            self?.delegate?.accountWasSynchronised(account: nil, error: .invalidSynchronisationData)
                        }
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .global()) { [weak self] in
            guard let user = self?.user, let pushToken = UserStorage.getPushToken(), let syncId = user.syncId else {
                self?.delegate?.synchronisationDidFail(error: .invalidSynchronisationData)
                return
            }
            self?.registrationAPIService.doInitUser(serverUrl: user.serverUrl,
                                                    syncId: syncId,
                                                    portalId: user.portalid,
                                                    userCode: user.userCode,
                                                    deviceId: pushToken,
                                                    syncDataArray: syncDataArray,
                                                    completion: { (result, error) in
                                                        if let error = error {
                                                            self?.delegate?.synchronisationDidFail(error: .custom(description: error.localizedDescription))
                                                        }
                                                    })
        }
    }
    
    private func getSecure(alias: String, strValue: String) -> String {
        if let privateKey = KeyStorage.getPrivateKey(key: alias) {
            let signature = CryptoKeyService.getSecure(id: strValue, privateKey: privateKey)
            return signature
        }
        return ""
    }
    
    private func userMetaForSynchronisation() -> UserMetaData? {
        if let qrData = dataForSync.first {
            let dict = URLParser.getDecodedParams(syncData: qrData)
            let userMeta = UserMetaData(dict: dict)
            if let _ = CoreDataManager.shared.getAccount(userName: userMeta.username, portalId: userMeta.portalid) {
                dataForSync.removeFirst()
                return userMetaForSynchronisation()
            } else {
                return userMeta
            }
        }
        
        return nil
    }
}

extension NoPassSynchronisationService: NoPassRegistrationServiceDelegate {
    public func registrationCode(code: String, isNeedConfirmationCode: Bool) {
        delegate?.syncRegistrationCode(code: code, isNeedConfirmationCode: isNeedConfirmationCode)
    }
    
    public func registration(account: NoPassAccount?, error: NopassError?) {
        delegate?.accountWasSynchronised(account: account, error: error)
        
        if isSyncRegistration {
            if let userMeta = userMetaForSynchronisation(),
               let enabled2FaMethod = enabled2FaMethod,
               let isScreenLock = isScreenLock {
                registrationService.appConfirm(user: userMeta, enabled2FaMethod: enabled2FaMethod, isScreenLock: isScreenLock)
                dataForSync.removeFirst()
            } else {
                delegate?.synchronisationDidFinish()
            }
        } else {
            if let userCode = account?.userCode {
                user?.userCode = userCode
            }
            
            syncAccounts()
        }
    }
}
