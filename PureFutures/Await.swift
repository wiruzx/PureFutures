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
private func timeFromTimeInterval(_ interval: TimeInterval) -> DispatchTime {
    if interval.isFinite {
        return .now() + Double(Int64(interval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
    } else {
        return .distantFuture
    }
}


/**
    
    Blocks current thread until callback is called or `interval` is over

    - parameter interval: How many seconds we're going to wait value
    - parameter block: Closure, parameter of which should be called with result value

    - returns: Optional value which will be nil if interval is over before value was set.

*/
internal func await<T>(_ interval: TimeInterval, block: ((T) -> Void) -> Void) -> T? {
    
    let semaphore = DispatchSemaphore(value: 0)
    
    var value: T? {
        didSet {
            semaphore.signal()
        }
    }
    
    block { value = $0 }
    
    semaphore.wait(timeout: timeFromTimeInterval(interval))
    
    return value
}
