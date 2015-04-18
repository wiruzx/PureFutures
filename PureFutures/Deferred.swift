//
//  Deferred.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

// MARK:- deferred creation functions

public func deferred<T>(@autoclosure block:  () -> T) -> Deferred<T> {
    let x = block()
    return deferred { x }
}

public func deferred<T>(block: () -> T) -> Deferred<T> {
    return deferred(ExecutionContext.DefaultPureOperationContext, block)
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
    
    public typealias Callback = T -> Void
    
    // MARK:- Private properties
    
    private var callbacks: [Callback] = []
    private let callbacksManagingQueue = dispatch_queue_create("com.wiruzx.PureFutures.Deferred.callbacksManaging", DISPATCH_QUEUE_SERIAL)
    
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
            ec.execute {
                c(result)
            }
        }
        
        dispatch_async(callbacksManagingQueue) {
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
        return onComplete(ExecutionContext.DefaultSideEffectsContext, c)
    }

    // MARK:- Internal methods

    internal func setValue(value: T?) {
        assert(self.value == nil, "Cannot complete Deferred more than once")
        assert(value != nil, "Result can't be nil")
        
        dispatch_async(callbacksManagingQueue) {
            
            self.value = value
            
            for callback in self.callbacks {
                callback(value!)
            }
            
            self.callbacks.removeAll()
        }

    }

}

public extension Deferred {
    
    // MARK:- andThen
    
    public func andThen(f: T -> Void) -> Deferred {
        return andThen(ExecutionContext.DefaultSideEffectsContext, f)
    }
    
    public func andThen(ec: ExecutionContextType, _ f: T -> Void) -> Deferred {
        return PureFutures.andThen(self, f)(ec)
    }
    
    // MARK:- forced
    
    public func forced() -> T {
        return PureFutures.forced(self)
    }
    
    public func forced(interval: NSTimeInterval) -> T? {
        return PureFutures.forced(self, interval)
    }
    
    // MARK:- map
    
    public func map<U>(f: T -> U) -> Deferred<U> {
        return map(ExecutionContext.DefaultPureOperationContext, f)
    }
    
    public func map<U>(ec: ExecutionContextType, _ f: T -> U) -> Deferred<U> {
        return PureFutures.map(self, f)(ec)
    }
    
    // MARK:- flatMap
    
    public func flatMap<U>(f: T -> Deferred<U>) -> Deferred<U> {
        return flatMap(ExecutionContext.DefaultPureOperationContext, f)
    }

    public func flatMap<U>(ec: ExecutionContextType, _ f: T -> Deferred<U>) -> Deferred<U> {
        return PureFutures.flatMap(self, f)(ec)
    }
    
    // MARK:- flatten
    
    public class func flatten(dx: Deferred<Deferred<T>>) -> Deferred<T> {
        return PureFutures.flatten(dx)
    }
    
    // MARK:- filter

    public func filter(p: T -> Bool) -> Deferred<T?> {
        return filter(ExecutionContext.DefaultPureOperationContext, p)
    }
    
    public func filter(ec: ExecutionContextType, _ p: T -> Bool) -> Deferred<T?> {
        return PureFutures.filter(self, p)(ec)
    }
    
    // MARK:- zip
    
    public func zip<U>(dx: Deferred<U>) -> Deferred<(T, U)> {
        return PureFutures.zip(self, dx)
    }
    
    // MARK:- reduce
    
    public class func reduce<U>(dxs: [Deferred], _ initial: U, _ combine: (U, T) -> U) -> Deferred<U> {
        return reduce(ExecutionContext.DefaultPureOperationContext, dxs, initial, combine)
    }
    
    public class func reduce<U>(ec: ExecutionContextType, _ dxs: [Deferred], _ initial: U, _ combine: (U, T) -> U) -> Deferred<U> {
        return PureFutures.reduce(dxs, initial, combine)(ec)
    }
    
    // MARK:- traverse
    
    public class func traverse<U>(xs: [T], _ f: T -> Deferred<U>) -> Deferred<[U]> {
        return traverse(ExecutionContext.DefaultPureOperationContext, xs, f)
    }
    
    public class func traverse<U>(ec: ExecutionContextType, _ xs: [T], _ f: T -> Deferred<U>) -> Deferred<[U]> {
        return PureFutures.traverse(xs, f)(ec)
    }
    
    // MARK:- sequence
    
    public class func sequence(dxs: [Deferred]) -> Deferred<[T]> {
        return PureFutures.sequence(dxs)
    }
    
    // MARK:- toFuture
    
    public class func toFuture<E>(dx: Deferred<Result<T, E>>) -> Future<T, E> {
        return PureFutures.toFuture(dx)
    }
    
}
