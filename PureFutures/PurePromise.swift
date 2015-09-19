//
//  PurePromise.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

/**

    A mutable container for the `Deferred`

    Allows you to complete `Deferred` that it holds

*/
public final class PurePromise<T> {
    
    // MARK:- Public properties
    
    /// `Deferred` which PurePromise will complete
    public let deferred = Deferred<T>()
    
    /// Shows if its deferred is completed
    public var isCompleted: Bool {
        return deferred.isCompleted
    }
    
    // MARK:- Initialization
    
    public init() {
    }
    
    // MARK:- PurePromiseType methods
    
    /**
    
        Completes PurePromise's deferred with given `value`
    
        Should be called only once! Second and next calls will raise an exception
    
        See also: `tryComplete`
    
        - parameter value: value that deferred will be completed with
    
    */
    public func complete(value: T) {
        deferred.setValue(value)
    }
    
    /**
    
        Completes PurePromise's deferred with given deferred
    
        Should be called only once! Second and next calls will raise an exception
    
        See also: `tryCompleteWith`
    
        - parameter deferred: Value that conforms to `DeferredType` protocol
    
    */
    public func completeWith<D: DeferredType where D.Element == T>(deferred: D) {
        deferred.onComplete(ExecutionContext.DefaultPureOperationContext) { self.complete($0) }
    }
    
    // MARK:- Other methods
    
    /**
    
        Tries to complete PurePromise's deferred with given `value`.
    
        If deferred was already completed returns `false`, otherwise returns `true`
    
        See also: `complete`
    
        - parameter value: value that deferred will be completed with
    
        - returns: Bool which says if completing was successful or not

    */
    public func tryComplete(value: T) -> Bool {
        if isCompleted {
            return false
        } else {
            complete(value)
            return true
        }
    }
    
    /**
    
        Tries to complete PurePromise's deferred with given deferred
    
        If deferred has already completed returns `false`, otherwise returns `true`
    
        See also: `completeWith`
    
        - parameter deferred: Value that should conform to `DeferredType` protocol
    
        - returns: Bool which says if completing was successful or not

    */
    public func tryCompleteWith<D: DeferredType where D.Element == T>(deferred: D) {
        deferred.onComplete(ExecutionContext.DefaultPureOperationContext) { self.tryComplete($0) }
    }
    
}
