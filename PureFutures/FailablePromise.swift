//
//  FailablePromise.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class FailablePromise<T, E> {
    
    private let promise = Promise<Result<T, E>>()
    
    public var future: Future<T, E> {
        return Future(deferred: promise.deferred)
    }
    
    public func complete(value: Result<T, E>) {
        promise.complete(value)
    }
    
    public func success(value: T) {
        complete(.Success(Box(value)))
    }
    
    public func failure(error: E) {
        complete(.Error(Box(error)))
    }
    
    public func completeWith(value: Future<T, E>) {
        promise.completeWith(value.deferred)
    }
    
}
