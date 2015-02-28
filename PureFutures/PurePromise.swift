//
//  PurePromise.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class PurePromise<T>: PurePromiseType {
    
    // MARK:- Public properties
    
    public private(set) var deferred = Deferred<T>()
    
    // MARK:- Initialization
    
    public init() { }
    
    // MARK:- PurePromiseType methods
    
    public func complete(value: T) {
        deferred.value = value
    }
    
    public func completeWith(deferred: Deferred<T>) {
        self.deferred = deferred
    }
}

extension PurePromise: SinkType {
    public func put(x: T) {
        complete(x)
    }
}
