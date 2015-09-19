//
//  Await.swift
//  PureFutures
//
//  Created by Victor Shamanov on 3/1/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

/**

    Converts NSTimeInterval to dispatch_time_t

    - parameter inverval: infinite of finite NSTimeInterval

    - returns: dispatch_time_t value

*/
private func timeFromTimeInterval(interval: NSTimeInterval) -> dispatch_time_t {
    if interval.isFinite {
        return dispatch_time(DISPATCH_TIME_NOW, Int64(interval * Double(NSEC_PER_SEC)))
    } else {
        return DISPATCH_TIME_FOREVER
    }
}


/**
    
    Blocks current thread until callback is called or `interval` is over

    - parameter interval: How many seconds we're going to wait value
    - parameter block: Closure, parameter of which should be called with result value

    - returns: Optional value which will be nil if interval is over before value was set.

*/
internal func await<T>(interval: NSTimeInterval, block: (T -> Void) -> Void) -> T? {
    
    let semaphore = dispatch_semaphore_create(0)
    
    var value: T? {
        didSet {
            dispatch_semaphore_signal(semaphore)
        }
    }
    
    block { value = $0 }
    
    dispatch_semaphore_wait(semaphore, timeFromTimeInterval(interval))
    
    return value
}
