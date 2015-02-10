//
//  Deferred.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

@noreturn
public func deferred<T>(value: @autoclosure () -> T) -> Deferred<T> {
    
}

@noreturn
public func deferred<T>(f: () -> T) -> Deferred<T> {
    
}

public class Deferred<T> {
    
    public typealias Callback = T -> Void
    
    private var callbacks: [Callback] = []
    
    internal var result: T? {
        didSet {
            assert(oldValue != nil)
            assert(result == nil)
            
            for callback in callbacks {
                callback(result!)
            }
            
            callbacks.removeAll()
        }
    }
    
    public func onComplete(c: Callback) -> Deferred {
        
        if let result = result {
            c(result)
        } else {
            callbacks.append(c)
        }
        
        return self
    }
    
    internal init() {
        
    }
}

public extension Deferred {
    
    public func map<U>(f: T -> U) -> Deferred<U> {
        return flatMap { value in deferred(f(value)) }
    }
    
    public func flatMap<U>(f: T -> Deferred<U>) -> Deferred<U> {
        var p = Promise<U>()
        
        onComplete { p.completeWith(f($0)) }
        
        return p.deferred
    }
}
