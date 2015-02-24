//
//  Promise.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class Promise<T>: PromiseType {
    
    typealias DeferredType = Deferred<T>
    
    // MARK:- Private properties
    
    public private(set) var deferred = Deferred<T>()
    
    // MARK:- Initialization
    
    public init() { }
    
    // MARK:- Public methods
    
    public func complete(value: T) {
        deferred.result = value
    }
    
    public func completeWith(deferred: Deferred<T>) {
        self.deferred = deferred
    }
}

extension Promise: SinkType {
    typealias Element = T
    
    public func put(x: Element) {
        complete(x)
    }
}
