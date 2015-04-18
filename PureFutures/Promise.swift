//
//  Promise.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public struct Promise<T, E>: PromiseType {
    
    typealias Element = Result<T, E>
    
    // MARK:- Public properties
    
    public let future = Future<T, E>()
    
    // MARK:- Initialization
    
    public init() {
    }
    
    // MARK:- PromiseType methods
    
    public func complete(value: Result<T, E>) {
        future.value = value
    }
    
    public func completeWith<D: DeferredType where D.Element == Element>(deferred: D) {
        deferred.onComplete(ExecutionContext.DefaultPureOperationContext) { self.complete($0) }
    }
    
    public func success(value: T) {
        complete(Result(value))
    }
    
    public func error(error: E) {
        complete(Result(error))
    }
}
