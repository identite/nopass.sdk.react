//
//  LogMessage.swift
//  NoPassSDK
//
//  Created by Vlad Krupnik on 20.08.2020.
//  Copyright © 2020 PSA. All rights reserved.
//

import Foundation

fileprivate var isLogEnabled: Bool = false

public func setLogEnabled(_ enabled: Bool) {
    isLogEnabled = enabled
}

func logMessage(_ message: String,
                fileName: String = #file,
                functionName: String = #function,
                lineNumber: Int = #line,
                columnNumber: Int = #column) {
    if isLogEnabled {
        print("Called by \(fileName) - \(functionName) at line \(lineNumber)[\(columnNumber) \n \(message) ")
    }
}
