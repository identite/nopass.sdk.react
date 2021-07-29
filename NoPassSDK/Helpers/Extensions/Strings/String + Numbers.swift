//
//  String + Numbers.swift
//  Mapd
//
//  Created by Влад on 9/30/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation

extension String {
    
    func hexToDecial() -> BigUInt? {
        if let value = BigUInt(self.uppercased(), radix: 16) {
            return value
        }
        return nil
    }
    
    func cleare() -> String {
        return  String(self.filter { !" \\ \n\t\r".contains($0) })
    }
    
    
}

