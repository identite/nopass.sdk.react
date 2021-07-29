//
//  OtpServiceProtocol.swift
//  Mapd
//
//  Created by Влад on 12/31/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import UIKit

protocol OtpServiceProtocol {
    func getKeyphase(_ key: String,userseed : String,authID: String, refreshTime: Int) -> (String,Int)
    func getSVGImage(keyphrase: Int) -> UIImage
    func getCode(keyphrase: Int) -> String
}
