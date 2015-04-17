//
//  Deferred.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func deferred<T>(@autoclosure block:  () -> T) -> Deferred<T> {
    return deferred(block)
}

public func deferred<T>(block: () -> T) -> Deferred<T> {
    return deferred(dispatch_get_global_queue(0, 0), block)
}

public func deferred<T>(ec: ExecutionContextType, block: () -> T) -> Deferred<T> {
    let p = PurePromise<T>()
    
    ec.execute {
        p.complete(block())
    }
    
    return p.deferred
}

public final class Deferred<T>: DeferredType {
    
    // MARK:- Type declarations
    
    typealias Element = T
    
    public typealias Callback = T -> Void
    
    // MARK:- Private properties
    
    private var callbacks: [Callback] = []
    private let callbacksManagingQueue = dispatch_queue_create("com.wiruzx.PureFutures.Deferred.callbacksManaging", DISPATCH_QUEUE_SERIAL)
    private let callbacksExecutingQueue = dispatch_queue_create("com.wiruzx.PureFutures.Deferred.callbacksExecuting", DISPATCH_QUEUE_SERIAL)
    
    // MARK:- Public properties
    
    public private(set) var value: T?
    
    // MARK:- Initialization
    
    internal init() {
        
    }
    
    // MARK:- DeferredType methods
    
    public init(_ x: T) {
        setValue(x)
    }
    
    public func onComplete(ec: ExecutionContextType, _ c: Callback) -> Deferred {
        
        let callbackInContext: T -> Void = { result in
            dispatch_sync(self.callbacksExecutingQueue) {
                ec.execute {
                    c(result)
                }
                return
            }
        }
        
        dispatch_sync(callbacksManagingQueue) {
            if let result = self.value {
                callbackInContext(result)
            } else {
                self.callbacks.append(callbackInContext)
            }
        }
        
        return self
    }
    
    // MARK:- Convenience methods
    
    public func onComplete(c: Callback) -> Deferred {
        return onComplete(defaultContext, c)
    }

    // MARK:- Internal methods

    internal func setValue(value: T?) {
        assert(self.value == nil, "Cannot complete Deferred more than once")
        assert(value != nil, "Result can't be nil")
        
        dispatch_sync(callbacksManagingQueue) {
            
            self.value = value
            
            for callback in self.callbacks {
                callback(value!)
            }
            
            self.callbacks.removeAll()
        }

    }

}

public extension Deferred {
    
    // MARK:- Convenience methods
    
    public func andThen(f: T -> Void) -> Deferred {
        return andThen(defaultContext, f)
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
        return zip(defaultContext, dx)
    }
    
    public class func flatten(dx: Deferred<Deferred<T>>) -> Deferred<T> {
        return flatten(defaultContext, dx)
    }
    
    public class func reduce<U>(dxs: [Deferred], _ initial: U, _ combine: (U, T) -> U) -> Deferred<U> {
        return reduce(defaultContext, dxs, initial, combine)
    }
    
    public class func traverse<U>(xs: [T], _ f: T -> Deferred<U>) -> Deferred<[U]> {
        return traverse(defaultContext, xs, f)
    }
    
    public class func sequence(dxs: [Deferred]) -> Deferred<[T]> {
        return sequence(defaultContext, dxs)
    }
    
    // MARK:- Original methods
    
    public func andThen(ec: ExecutionContextType, _ f: T -> Void) -> Deferred {
        return PureFutures.andThen(self, f)(ec)
    }
    
    public func forced() -> T {
        return PureFutures.forced(self)
    }
    
    public func forced(interval: NSTimeInterval) -> T? {
        return PureFutures.forced(self, interval)
    }
    
    public func map<U>(ec: ExecutionContextType, _ f: T -> U) -> Deferred<U> {
        return PureFutures.map(self, f)(ec)
    }
    
    public func flatMap<U>(ec: ExecutionContextType, _ f: T -> Deferred<U>) -> Deferred<U> {
        return PureFutures.flatMap(self, f)(ec)
    }

    public func filter(ec: ExecutionContextType, _ p: T -> Bool) -> Deferred<T?> {
        return PureFutures.filter(self, p)(ec)
    }
    
    public func zip<U>(ec: ExecutionContextType, _ dx: Deferred<U>) -> Deferred<(T, U)> {
        return PureFutures.zip(self, dx)(ec)
    }
    
    public class func flatten(ec: ExecutionContextType, _ dx: Deferred<Deferred<T>>) -> Deferred<T> {
        return PureFutures.flatten(dx)(ec)
    }
    
    public class func reduce<U>(ec: ExecutionContextType, _ dxs: [Deferred], _ initial: U, _ combine: (U, T) -> U) -> Deferred<U> {
        return PureFutures.reduce(dxs, initial, combine)(ec)
    }
    
    public class func traverse<U>(ec: ExecutionContextType, _ xs: [T], _ f: T -> Deferred<U>) -> Deferred<[U]> {
        return PureFutures.traverse(xs, f)(ec)
    }
    
    public class func sequence(ec: ExecutionContextType, _ dxs: [Deferred]) -> Deferred<[T]> {
        return PureFutures.sequence(dxs)(ec)
    }
    
}
