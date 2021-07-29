//
//  Data + hex.swift
//  Mapd
//
//  Created by Влад on 9/30/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

extension Data {
    
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }

    var hexDescription: String {
        return reduce("") { $0 + String(format: "%02x", $1) }
    }

    
    func hexEncodedString() -> String {
        return String(self.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(Data.hexAlphabet[Int(value/16)])
            result.append(Data.hexAlphabet[Int(value%16)])
        }))
    }
}

