import Foundation

public struct NoPassAccount {
    public let userCode: String
    public let accountName: String
    public let seed: String
    public let crearedDate: Date
    public let hex: String
    
    public let portalName: String
    public let portalId: String
    public let isAccountBackup: Bool
    
    public func toDictionaryForRN() -> Dictionary<String, Any> {
        return ["userCode": userCode,
                "accountName": accountName,
                "seed": seed,
                "createdDate": crearedDate.stringDate(timeZone: TimeZone(abbreviation: "UTC") ?? .current),
                "hex": hex,
                "portalName": portalName,
                "portalId": portalId,
                "isAccountBackup": isAccountBackup]
    }
}
