//
//  Promise.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public class Promise<T> {
    
    private var _deferred = Deferred<T>()
    
    public var deferred: Deferred<T> {
        return _deferred
    }
    
    public init() {
    }
    
    public func complete(value: T) {
        _deferred.result = value
    }
    
    public func completeWith(deferred: Deferred<T>) {
        _deferred = deferred
    }
}
