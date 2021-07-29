//
//  OtpService.swift
//  Mapd
//
//  Created by Влад on 12/31/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import UIKit
import CommonCrypto

final class OtpService  {
    
    init() {}
    
    func getOTP(authId: String, userSeed: String, authDelay: Int) -> (String,Int?) {
        
        // Next Delay calculate
        let delay = Double(authDelay) / Double(1000)
        
        let time = Double(Date().timeIntervalSince1970) + delay
        
        
        let updatedDate = Date(timeIntervalSince1970: Double(time))
        let updateTime = updatedDate.stringDate(timeZone: TimeZone(abbreviation: "UTC") ?? .current)
        
        var calendar = Calendar.current
        
        if let timeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = timeZone
        }
        
        let second = calendar.component(.second, from: updatedDate)
        
        
        var nextDate: Date = updatedDate
        
        if second >= 30 {
            nextDate = nextDate.addingTimeInterval(Double(60 - second))
        } else {
            nextDate = nextDate.addingTimeInterval(Double(30 - second))
        }
        
        
        var input = Int(nextDate.timeIntervalSince1970).data
        input.reverse()
        
        guard let challenge = userSeed.data(using: .utf8), let key = authId.data(using: .utf8) else {
            return  (updateTime,nil)
            
        }
        
        input.append(challenge)
        
        
        guard let hash = self.hmac(hashName: "SHA1", message: input, key: key), let lastByte = hash.last else {return (updateTime,nil)}
        
        let offset = Int(lastByte) & 0xf
        
        let binary = (Int(hash[offset] & 0x7f) << 24) | (Int(hash[offset + 1] & 0xff) << 16) |
            (Int(hash[offset + 2] & 0xff) << 8) | Int(hash[offset + 3] & 0xff)
        
        
        
        return (updateTime,binary)
        
    }
    
    func hmac(hashName:String, message:Data, key:Data) -> Data? {
        let algos = ["SHA1":   (kCCHmacAlgSHA1,   CC_SHA1_DIGEST_LENGTH),
                     "MD5":    (kCCHmacAlgMD5,    CC_MD5_DIGEST_LENGTH),
                     "SHA224": (kCCHmacAlgSHA224, CC_SHA224_DIGEST_LENGTH),
                     "SHA256": (kCCHmacAlgSHA256, CC_SHA256_DIGEST_LENGTH),
                     "SHA384": (kCCHmacAlgSHA384, CC_SHA384_DIGEST_LENGTH),
                     "SHA512": (kCCHmacAlgSHA512, CC_SHA512_DIGEST_LENGTH)]
        guard let (hashAlgorithm, length) = algos[hashName]  else { return nil }
        var macData = Data(count: Int(length))
        
        macData.withUnsafeMutableBytes {macBytes in
            message.withUnsafeBytes {messageBytes in
                key.withUnsafeBytes {keyBytes in
                    CCHmac(CCHmacAlgorithm(hashAlgorithm),
                           keyBytes,     key.count,
                           messageBytes, message.count,
                           macBytes)
                }
            }
        }
        return macData
    }
    
    
    func getCode(keyphrase: Int) -> String {
        var code = (keyphrase % 1000).description
        while code.count != 3 {
            code.insert("0", at: code.startIndex)
        }
        return code
    }
    
    
    
    
}


extension Int {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<Int>.size)
    }
}


extension TimeInterval {
    var minuteSecondMS: String {
        return String(format:"%d:%02d.%03d", minute, second, millisecond)
    }
    var minute: Int {
        return Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        return Int(truncatingRemainder(dividingBy: 60))
    }
    var millisecond: Int {
        return Int((self*1000).truncatingRemainder(dividingBy: 1000))
    }
}

extension Int {
    var msToSeconds: Double {
        return Double(self) / 1000
    }
}
