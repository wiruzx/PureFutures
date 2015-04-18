//
//  PurePromise.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public struct PurePromise<T> {
    
    // MARK:- Public properties
    
    public let deferred = Deferred<T>()
    
    // MARK:- Initialization
    
    public init() {
    }
    
    // MARK:- PurePromiseType methods
    
    public func complete(value: T) {
        deferred.setValue(value)
    }
    
    public func completeWith<D: DeferredType where D.Element == T>(deferred: D) {
        deferred.onComplete(ExecutionContext.DefaultPureOperationContext) { self.complete($0) }
    }
    
}
