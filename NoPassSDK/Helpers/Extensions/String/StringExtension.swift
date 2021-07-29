//
//  StringExtension.swift
//  NoPassSDK
//
//  Created by Artsiom Shmaenkov on 23.02.2021.
//  Copyright © 2021 PSA. All rights reserved.
//

import Foundation

extension String {
    func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
    
    func removeHostName() -> String {
        var name = self.replacingOccurrences(of: "https://", with: "")
        if name.last == "/" {
            name.removeLast()
        }
        return name
    }
}
