//
//  Deferred.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class Deferred<T>: DeferredType {
    
    typealias Element = T
    
    // MARK:- Type declarations
    
    public typealias Callback = T -> Void
    
    // MARK:- Private properties
    
    private var callbacks: [Callback] = []
    
    // MARK:- Public properties
    
    public internal(set) var value: T? {
        didSet {
            assert(oldValue == nil, "Cannot complete Deferred more than once")
            assert(value != nil, "Result can't be nil")
            
            for callback in callbacks {
                callback(value!)
            }
            
            callbacks.removeAll()
        }
    }
    
    // MARK:- Initialization
    
    internal init() {
        
    }
    
    public init(_ f: () -> T) {
        self.value = f()
    }
    
    public convenience init(_ f: @autoclosure () -> T) {
        self.init(f as () -> T)
    }
    
    // MARK:- DeferredType methods
    
    public init(_ x: T) {
        self.value = x
    }
    
    public func onComplete(c: Callback) -> Deferred {
        
        if let result = value {
            c(result)
        } else {
            callbacks.append(c)
        }
        
        return self
    }
}

public extension Deferred {
    
    public func map<U>(f: T -> U) -> Deferred<U> {
        return PureFutures.map(self, f)
    }
    
    public func flatMap<U>(f: T -> Deferred<U>) -> Deferred<U> {
        return PureFutures.flatMap(self, f)
    }

    public func filter(p: T -> Bool) -> Deferred<T?> {
        return PureFutures.filter(self, p)
    }
    
}
