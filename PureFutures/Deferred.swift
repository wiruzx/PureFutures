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
    
    public convenience init(_ f: @autoclosure () -> T) {
        self.init(f as () -> T)
    }
    
    public convenience init(_ f: () -> T) {
        self.init(ec: defaultContext, f)
    }
    
    public init(ec: ExecutionContextType, f: () -> T) {
        ec.execute {
            self.value = f()
        }
    }
    
    // MARK:- DeferredType methods
    
    public init(_ x: T) {
        self.value = x
    }
    
    public func onComplete(ec: ExecutionContextType, c: Callback) -> Deferred {
        
        let callbackInContext = { result in
            ec.execute {
                c(result)
            }
        }
        
        if let result = value {
            callbackInContext(result)
        } else {
            callbacks.append(callbackInContext)
        }
        
        return self
    }
    
    // MARK:- Convenience methods
    
    public func onComplete(c: Callback) -> Deferred {
        return onComplete(defaultContext, c: c)
    }
}

public extension Deferred {
    
    // MARK:- Convenience methods
    
    public func forced() -> T {
        return forced(defaultContext)
    }
    
    public func forced(interval: NSTimeInterval) -> T? {
        return forced(defaultContext, interval: interval)
    }
    
    public func map<U>(f: T -> U) -> Deferred<U> {
        return map(defaultContext, f)
    }
    
    public func flatMap<U>(f: T -> Deferred<U>) -> Deferred<U> {
        return flatMap(defaultContext, f)
    }

    public func filter(p: T -> Bool) -> Deferred<T?> {
        return filter(defaultContext, p)
    }
    
    public func zip<U>(dx: Deferred<U>) -> Deferred<(T, U)> {
        return zip(defaultContext, dx: dx)
    }
    
    public class func reduce<U>(dxs: [Deferred], initial: U, combine: (U, T) -> U) -> Deferred<U> {
        return reduce(defaultContext, dxs: dxs, initial: initial, combine: combine)
    }
    
    public class func traverse<U>(xs: [T], f: T -> Deferred<U>) -> Deferred<[U]> {
        return traverse(defaultContext, xs: xs, f: f)
    }
    
    public class func sequence(dxs: [Deferred]) -> Deferred<[T]> {
        return sequence(defaultContext, dxs: dxs)
    }
    
    // MARK:- With execution context
    
    public func forced(ec: ExecutionContextType) -> T {
        return PureFutures.forced(self)(ec: ec)
    }
    
    public func forced(ec: ExecutionContextType, interval: NSTimeInterval) -> T? {
        return PureFutures.forced(self, interval)(ec: ec)
    }
    
    public func map<U>(ec: ExecutionContextType, f: T -> U) -> Deferred<U> {
        return PureFutures.map(self, f)(ec: ec)
    }
    
    public func flatMap<U>(ec: ExecutionContextType, f: T -> Deferred<U>) -> Deferred<U> {
        return PureFutures.flatMap(self, f)(ec: ec)
    }

    public func filter(ec: ExecutionContextType, p: T -> Bool) -> Deferred<T?> {
        return PureFutures.filter(self, p)(ec: ec)
    }
    
    public func zip<U>(ec: ExecutionContextType, dx: Deferred<U>) -> Deferred<(T, U)> {
        return PureFutures.zip(self, dx)(ec: ec)
    }
    
    public class func reduce<U>(ec: ExecutionContextType, dxs: [Deferred], initial: U, combine: (U, T) -> U) -> Deferred<U> {
        return PureFutures.reduce(dxs, initial, combine)(ec: ec)
    }
    
    public class func traverse<U>(ec: ExecutionContextType, xs: [T], f: T -> Deferred<U>) -> Deferred<[U]> {
        return PureFutures.traverse(xs, f)(ec: ec)
    }
    
    public class func sequence(ec: ExecutionContextType, dxs: [Deferred]) -> Deferred<[T]> {
        return PureFutures.sequence(dxs)(ec: ec)
    }
    
}
