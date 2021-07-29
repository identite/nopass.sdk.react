//
//  Collection + Bounds.swift
//  Mapd
//
//  Created by Vlad Krupnik on 17/03/2020.
//  Copyright © 2020 PSA. All rights reserved.
//

import Foundation

extension Collection {

    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
