//
//  Deferred.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

// MARK:- deferred creation functions

/**
    Creates a new Deferred<T> which value become
    result of execution `block` on background thread

    :param: block function, which result become value of Deferred

    :returns: a new Deferred<T>
*/
public func deferred<T>(block: () -> T) -> Deferred<T> {
    return deferred(ExecutionContext.DefaultPureOperationContext, block)
}

/**
    Creates a new Deferred<T> which value become
    result of execution `block` on `ec` execution context

    :param: ec execution context of block
    :param: block function, which result become value of Deferred

    :returns: a new Deferred<T>
*/
public func deferred<T>(ec: ExecutionContextType, block: () -> T) -> Deferred<T> {
    let p = PurePromise<T>()
    
    ec.execute {
        p.complete(block())
    }
    
    return p.deferred
}

// MARK:- Deferred

/// Represents value which will be available in the future.
public final class Deferred<T>: DeferredType {
    
    // MARK:- Type declarations
    
    public typealias Callback = T -> Void
    
    // MARK:- Private properties
    
    private var callbacks: [Callback] = []
    private let callbacksManagingQueue = dispatch_queue_create("com.wiruzx.PureFutures.Deferred.callbacksManaging", DISPATCH_QUEUE_SERIAL)
    
    // MARK:- Public properties
    
    /// Value of Deferred
    public private(set) var value: T?
    
    /// Shows if Deferred is completed
    public var isCompleted: Bool {
        return value != nil
    }
    
    // MARK:- Initialization
    
    internal init() {
    }
    
    // MARK:- DeferredType methods
    
    /// Creates immediately completed Deferred with given value
    public init(_ x: T) {
        setValue(x)
    }
    
    /**
        Register an callback which will be called when Deferred completed
    
        :param: ec execution context of callback
        :param: c callback
    
        :returns: Returns itself for chaining operations
    */
    public func onComplete(ec: ExecutionContextType, _ c: Callback) -> Deferred {
        
        let callbackInContext = { result in
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
    
    /**
        Register an callback which will be called on main thread when Deferred completed
    
        :param: c callback
    
        :returns: Returns itself for chaining operations
    */
    public func onComplete(c: Callback) -> Deferred {
        return onComplete(ExecutionContext.DefaultSideEffectsContext, c)
    }

    // MARK:- Internal methods

    internal func setValue(value: T) {
        assert(self.value == nil, "Value can be set only once")
        
        dispatch_sync(callbacksManagingQueue) {
            
            self.value = value
            
            for callback in self.callbacks {
                callback(value)
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
