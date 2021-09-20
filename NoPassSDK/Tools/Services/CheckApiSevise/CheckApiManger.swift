
import Foundation

open class CheckApiManger: CheckApiMangerProtocol {

    private let network: NetworkManager

    init() {
        self.network = NetworkManager()
    }

    func checkServerVersion(_ serverUrl: String, apiVersionFlowType: ApiVersionFlowType, completion: ((_ serverVersion: ApiVersionModel?, _ error: NSError?) -> Void)?) {

        let apiPath = "\(serverUrl)version"
        let tag = REQUEST_TAG.version.rawValue
        network.sendRequest(urlString: apiPath, params: nil, completion: { [unowned self] (json, error) in
            if let jsonResult = json as? JSON {
                let serverApiVersion = ApiVersionModel(json: jsonResult["result"]["apiVersion"])
                
                completion?(serverApiVersion, self.isSupportedVersion(serverApiVersion: serverApiVersion, apiVersionFlowType: apiVersionFlowType))
            } else {
                completion?(nil, error)
            }
        }, method: "GET", urlEncoding: JSONEncoding.default, requestTag: tag)
    }

    func isSupportedVersion(serverApiVersion: ApiVersionModel,apiVersionFlowType: ApiVersionFlowType) -> NSError? {
        let appApiVersion = ApiVersionModel()
        var isSupportedVersion = true
        switch apiVersionFlowType {
        case .auth:
            isSupportedVersion = isMajorVersionEqual(server: serverApiVersion.userAuthVersion, app: appApiVersion.userAuthVersion)
        case .registration:
            isSupportedVersion = isMajorVersionEqual(server: serverApiVersion.userRegistrationVersion, app: appApiVersion.userRegistrationVersion)
        case .delete:
            isSupportedVersion = isMajorVersionEqual(server: serverApiVersion.userDeletionVersion, app: appApiVersion.userDeletionVersion)
        case .encryption:
            isSupportedVersion = isMajorVersionEqual(server: serverApiVersion.encryptionVersion, app: appApiVersion.encryptionVersion)
        case .update:
            isSupportedVersion = isMajorVersionEqual(server: serverApiVersion.userUpdatingVersion, app: appApiVersion.userUpdatingVersion)
        case .restoring:
            isSupportedVersion = isMajorVersionEqual(server: serverApiVersion.userRestoringVersion, app: appApiVersion.userRestoringVersion)
        }
        
        if !isSupportedVersion {
           return NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "The operation is not available. Please, update the application."])
        }
        
        return nil
    }
    
    
    private func isMajorVersionEqual(server: String, app: String) -> Bool {
        return getMajorVersion(version: server) == getMajorVersion(version: app)
    }
    
    private func getMajorVersion(version: String) -> String {
        let delimiter = "."
        let token = version.components(separatedBy: delimiter)
        return token.first ?? ""
    }
    
    
    private func getMinorVersion(version: String) -> String {
        let delimiter = "."
        let token = version.components(separatedBy: delimiter)
        return token.last ?? ""
    }
    
}
