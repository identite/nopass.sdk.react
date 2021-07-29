//
//  LocalAuthService.swift
//  Mapd
//
//  Created by Влад on 11/15/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation
import LocalAuthentication
import UIKit



 enum BiometricType : String {
    case null = "null"
    case NativeFingerPrint = "NativeFingerPrint"
    case NativeFaceId = "NativeFaceId"
    case NativePinCode = "NativePinCode"
    case PinCode = "PinCode"
}


