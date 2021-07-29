//
//  ColorsService.swift
//  Mapd
//
//  Created by Влад on 12/19/19.
//  Copyright © 2019 PSA. All rights reserved.
//

import UIKit


final class ColorsService {
   
    private static var colors: [String] = ["6D4C41", "757575", "78909C", "827717", "B71C1C", "EF5350", "E18080", "880E4F", "6A1B9A", "9575CD", "4A148C", "1A237E", "7A9AD8", "0D47A1", "0288D1", "006064", "0097A7", "85CB99", "1B5E20", "558B2F"]
    
    
    static func getHex(number: Int) -> String  {
        if number <= colors.count - 1 && number >= 0 {
            return colors[number]
        }
        return "1A237E"
    }
}


