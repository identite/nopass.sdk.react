//
//  Connectivity.swift
//  Mapd
//
//  Created by Vlad Krupnik on 10/04/2020.
//  Copyright © 2020 PSA. All rights reserved.
//


class Connectivity {
    class var isConnectedToInternet:Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
}
