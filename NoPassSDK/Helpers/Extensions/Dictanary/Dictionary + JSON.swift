//
//  Dictionary + JSON.swift
//  Mapd
//
//  Created by Влад on 10/1/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

extension Dictionary {
    var json: String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.sortedKeys, .prettyPrinted])
            return String(bytes: jsonData, encoding: String.Encoding.utf8)
        } catch {
            return nil
        }
    }
}


