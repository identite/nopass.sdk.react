//
//  Device.swift
//  Mapd
//
//  Created by Влад on 12/3/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import UIKit

struct Device {
    static let isIphone = UIDevice.current.userInterfaceIdiom == .phone
    static let isIpad = UIDevice.current.userInterfaceIdiom == .pad
    static let isIpadPro = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH > 1024
    // 5, 5s, 5c, SE
    static let isIphone_5 = ScreenSize.SCREEN_HEIGHT == 568
    // 6, 6s, 7, 8
    static let isIphone_6 = ScreenSize.SCREEN_HEIGHT == 667
    // 6+, 6s+. 7+, 8+
    static let isIphone_6Plus = ScreenSize.SCREEN_HEIGHT == 736
    // X, XS
    static let isIphone_X = ScreenSize.SCREEN_HEIGHT == 812
    // XR, XS MAX
    static let isIphone_XR = ScreenSize.SCREEN_HEIGHT == 896

    static func isJailbreak() -> Bool {
        if TARGET_IPHONE_SIMULATOR != 1 {
            return FileManager.default.fileExists(atPath: "Applications/Cydia.app")
                || FileManager.default.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib")
                || FileManager.default.fileExists(atPath: "/bin/bash")
                || FileManager.default.fileExists(atPath: "/usr/sbin/sshd")
                || FileManager.default.fileExists(atPath: "/etc/apt")
                || FileManager.default.fileExists(atPath: "/private/var/lib/apt/")
                || UIApplication.shared.canOpenURL(URL(string: "cydia://package/com.example.package")!)
                || isValidSanbox()
        }
        return false
    }

    static private func isValidSanbox() -> Bool {
        let stringToWrite = "Jailbreak Test"
        do
        {
            try stringToWrite.write(toFile: "/private/JailbreakTest.txt", atomically: true, encoding: String.Encoding.utf8)

            return true
        } catch {
            return false
        }
        

}


}

struct ScreenSize {
    static let SCREEN_WIDTH = UIScreen.main.bounds.size.width
    static let SCREEN_HEIGHT = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}
