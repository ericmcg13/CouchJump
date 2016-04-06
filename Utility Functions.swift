//
//  Utility Functions.swift
//  CouchJump
//
//  Created by Eric McGaughey on 10/22/15.
//  Copyright © 2015 Eric McGaughey. All rights reserved.
//

import Foundation



func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}