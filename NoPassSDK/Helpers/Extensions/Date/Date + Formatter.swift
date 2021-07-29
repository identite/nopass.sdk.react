//
//  Date + Formatter.swift
//  Mapd
//
//  Created by Влад on 10/23/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import Foundation


extension Date {
    public func stringDate(format: String = "yyyy-MM-dd'T'HH:mm:ss.SSS", timeZone: TimeZone = .current) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    public func stringDate(_ timeZone: TimeZone = .current, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.dateStyle = dateStyle
        dateFormatter.timeStyle = timeStyle
        return dateFormatter.string(from: self)
    }
}



extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
    
        static func - (lhs: Date, rhs: Date) -> TimeInterval {
            return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
        }

}

extension TimeInterval{

    func stringFromTimeInterval() -> String {

        let time = NSInteger(self)

        let ms = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d",hours,minutes,seconds,ms)

    }
}
