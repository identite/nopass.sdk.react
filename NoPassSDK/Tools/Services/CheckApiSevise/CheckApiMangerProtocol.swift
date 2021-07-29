//
//  CheckApiMangerProtocol.swift
//  Mapd
//
//  Created by Влад on 1/27/20.
//  Copyright © 2020 PSA. All rights reserved.
//

import Foundation

protocol CheckApiMangerProtocol {
    func checkServerVersion(_ serverUrl: String, apiVersionFlowType: ApiVersionFlowType, completion: ((_ serverApiVersion: ApiVersionModel?, _ error: NSError?) -> Void)?)
}
