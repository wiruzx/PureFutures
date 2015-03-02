//
//  Await.swift
//  PureFutures
//
//  Created by Victor Shamanov on 3/1/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

private func timeFromTimeInterval(interval: NSTimeInterval) -> dispatch_time_t {
    if interval.isFinite {
        return dispatch_time(DISPATCH_TIME_NOW, Int64(interval * Double(NSEC_PER_SEC)))
    } else {
        return DISPATCH_TIME_FOREVER
    }
}

internal func await<T>(interval: NSTimeInterval, block: (T -> Void) -> Void) -> T? {
    
    let semaphore = dispatch_semaphore_create(0)
    
    var value: T? {
        didSet {
            dispatch_semaphore_signal(semaphore)
        }
    }
    
    block { x in
        value = x
    }
    
    dispatch_semaphore_wait(semaphore, timeFromTimeInterval(interval))
    
    return value
}
