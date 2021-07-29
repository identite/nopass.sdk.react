//
//  URLParser.swift
//  Mapd
//
//  Created by Влад on 10/9/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

final class URLParser {
    
    static func getDecodedParam(string: String) -> [String: String]? {
        guard let decodedURL = URL(string: self.decodeURL(url: string) ?? "") else {
            return nil
        }
        var dict = [String: String]()
        let components = URLComponents(url: decodedURL, resolvingAgainstBaseURL: false)!
        if let queryItems = components.queryItems {
            for item in queryItems {
                dict[item.name] = item.value ?? ""
            }
        }
        return dict
    }
    
    static func decodeURL(url: String) -> String? {
        if let range = url.range(of: "referrer=") {
            let base64String = url[range.upperBound...].description
            let result = url.replacingOccurrences(of: "referrer=\(base64String)", with: base64String.base64Decoded() ?? "")
            return result.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        }
        return nil
    }
    
    static func getDecodedParams(syncData: String) -> [String: String] {
        var dict = [String: String]()
        let str = "?\(syncData.base64Decoded()?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        let components = URLComponents(string: str)
        if let queryItems = components?.queryItems {
            for item in queryItems {
                dict[item.name] = item.value ?? ""
            }
        }
        return dict
    }
}
