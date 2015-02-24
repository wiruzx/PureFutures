//
//  Promise.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class Promise<T>: PromiseProtocol {
    
    typealias DeferredType = Deferred<T>
    
    // MARK:- Private properties
    
    private var _deferred = Deferred<T>()
    
    // MARK:- Public properties
    
    public var deferred: Deferred<T> {
        return _deferred
    }
    
    // MARK:- Initialization
    
    public init() { }
    
    // MARK:- Public methods
    
    public func complete(value: T) {
        _deferred.result = value
    }
    
    public func completeWith(deferred: Deferred<T>) {
        _deferred = deferred
    }
}
