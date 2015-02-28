//
//  Deferred.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class Deferred<T>: DeferredType {
    
    // MARK:- Type declarations
    
    typealias Element = T
    
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
    
    public func zip<U>(x: Deferred<U>) -> Deferred<(T, U)> {
        return PureFutures.zip(self, x)
    }
    
    public class func reduce<U>(ds: [Deferred], initial: U, combine: (U, T) -> U) -> Deferred<U> {
        return PureFutures.reduce(ds, initial, combine)
    }
    
    public class func traverse<U>(ds: [T], f: T -> Deferred<U>) -> Deferred<[U]> {
        return PureFutures.traverse(ds, f)
    }
    
    public class func sequence(ds: [Deferred]) -> Deferred<[T]> {
        return PureFutures.sequence(ds)
    }
    
}
