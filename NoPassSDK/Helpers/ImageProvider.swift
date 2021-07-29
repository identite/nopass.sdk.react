//
//  ImageProvider.swift
//  NoPassSDK
//
//  Created by Artsiom Shmaenkov on 12.07.21.
//  Copyright © 2021 PSA. All rights reserved.
//

import UIKit

public class ImageProvider {
    public static func image(named: String) -> UIImage? {
        return UIImage(named: named, in: Bundle(for: self), compatibleWith: nil)
    }
}
