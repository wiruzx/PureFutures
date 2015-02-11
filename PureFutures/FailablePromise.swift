//
//  FailablePromise.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class FailablePromise<T, E> {
    
    private var _future = Future<T, E>()
    
    public var future: Future<T, E> {
        return _future
    }
    
    public func complete(value: Result<T, E>) {
        _future.deferred.result = value
    }
    
    public func success(value: T) {
        _future.deferred.result = .Success(Box(value))
    }
    
    public func failure(error: E) {
        _future.deferred.result = .Error(Box(error))
    }
    
    public func completeWith(future: Future<T, E>) {
        _future = future
    }
    
}
