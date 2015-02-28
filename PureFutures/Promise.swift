//
//  Promise.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class Promise<T, E>: PromiseType {
    
    public private(set) var future = Future<T, E>()
    
    public func complete(value: Result<T, E>) {
        future.result = value
    }
    public func success(value: T) {
        complete(Result(value))
    }
    
    public func error(error: E) {
        complete(Result(error))
    }
    
    public func completeWith(future: Future<T, E>) {
        self.future = future
    }
    
}

extension Promise: SinkType {
    public func put(x: Result<T, E>) {
        complete(x)
    }
}
