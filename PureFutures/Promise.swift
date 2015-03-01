//
//  Promise.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public struct Promise<T, E>: PromiseType {
    
    // MARK:- Public properties
    
    public let future = Future<T, E>()
    
    // MARK:- Initialization
    
    public init() {
    }
    
    // MARK:- PromiseType methods
    
    public func complete(value: Result<T, E>) {
        future.value = value
    }
    
    public func success(value: T) {
        complete(Result(value))
    }
    
    public func error(error: E) {
        complete(Result(error))
    }
    
    public func completeWith(future: Future<T, E>) {
        future.onComplete { self.complete($0) }
    }
    
}
