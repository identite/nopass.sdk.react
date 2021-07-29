import Foundation

public final class BackupAccountModel : Hashable {
    
    // TODO : add userid and portalname only for google
    public var userCode: String = ""
    public var username: String = ""
    public var portalid: String = ""
    public var portalName: String = ""
    public var apikey: String = ""
    public var isRestore: Bool = false
    
    init(username: String, userCode: String ,portalid: String, portalName: String, apikey: String, pinHash: String) {
        self.userCode = userCode
        self.username = username
        self.portalid = portalid
        self.apikey = apikey
        self.portalName = portalName
    }
    
    init(json: JSON) {
        self.userCode = json["userCode"].stringValue
        self.username = json["username"].stringValue
        self.portalid = json["portalid"].stringValue
        self.apikey = json["apikey"].stringValue
        self.portalName = json["portalname"].stringValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userCode)
        hasher.combine(portalid)
        hasher.combine(apikey)
    }
    
    public static func == (lhs: BackupAccountModel, rhs: BackupAccountModel) -> Bool {
        return lhs.userCode == rhs.userCode && lhs.portalid == rhs.portalid && lhs.apikey == rhs.apikey
    }    
}

extension BackupAccountModel {
    func toDictionary() -> [String: Any] {
        var result: [String: Any] = [:]
        result["userCode"] = userCode
        result["username"] = username
        result["portalid"] = portalid
        result["apikey"] = apikey
        result["portalname"] = portalName
        return result
    }
    
}
