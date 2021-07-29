//
//  DeclineType.swift
//  Mapd
//
//  Created by Влад on 10/23/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation


public enum DeclineType: String {
    
    case skipPressed = "skipPressed"
    case backPressed = "backPressed"
    case madeWrong = "madeWrong"
    case changedMind = "changedMind"
    case didNotSend = "didNotSend"
    case wrongCode = "wrongCode"
    case localAuthFailedPin = "localAuthFailedPin"
    case deviceDifferentTime = "deviceDifferentTime"
    
//    func dascription() -> String {
//        switch self {
//        case .skipPressed:
//            return "decline.skip.pressed".localized()
//        case .backPressed:
//            return "decline.back.pressed".localized()
//        case .madeWrong:
//            return "decline.was.mistake".localized()
//        case .changedMind:
//            return "decline.changed.mind".localized()
//        case .didNotSend:
//            return "decline.not.send.request".localized()
//        case .wrongCode:
//            return "decline.wrong.code".localized()
//        case .localAuthFailedPin:
//            return "declibe.failed.pin".localized()
//        case .deviceDifferentTime:
//            return "Device Different Time".localized()
//            
//        }
//    }
    

}
