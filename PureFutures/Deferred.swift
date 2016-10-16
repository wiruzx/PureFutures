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

    Creates a new Deferred<T> whose value become
    result of execution `block` on background thread

    - parameter block: function, which result become value of Deferred

    - returns: a new Deferred<T>
    
*/
public func deferred<T>(_ block: @escaping () -> T) -> Deferred<T> {
    return deferred(Pure, block: block)
}

/**

    Creates a new Deferred<T> whose value become
    result of execution `block` on `ec` execution context

    - parameter ec: execution context of block
    - parameter block: function, which result become value of Deferred

    - returns: a new Deferred<T>
    
*/
public func deferred<T>(_ ec: ExecutionContextType, block: @escaping () -> T) -> Deferred<T> {
    let p = PurePromise<T>()
    
    ec.execute {
        p.complete(block())
    }
    
    return p.deferred
}

// MARK:- Deferred

/// Represents a value that will be available in the future.
public final class Deferred<T>: DeferredType {
    
    // MARK:- Type declarations
    
    public typealias Value = T
    public typealias Callback = (T) -> Void
    
    // MARK:- Public properties
    
    /// Value of Deferred
    public private(set) var value: T?
    
    /// Shows if Deferred is completed
    public var isCompleted: Bool {
        return value != nil
    }
    
    // MARK:- Private properties
    
    private var callbacks: [Callback] = []
    private let callbacksManagingQueue = DispatchQueue(label: "com.wiruzx.PureFutures.Deferred.callbacksManaging", attributes: [])
    
    
    // MARK:- Initialization
    
    internal init() {
    }
    
    public init<D: DeferredType>(deferred: D) where D.Value == T {
        deferred.onComplete(Pure, setValue)
    }
    
    /// Creates immediately completed Deferred with given value
    public static func completed(_ x: T) -> Deferred {
        let d = Deferred()
        d.value = x
        return d
    }
    
    // MARK:- DeferredType methods
    
    /**
    
        Register an callback which will be called when Deferred completed
    
        - parameter ec: execution context of callback
        - parameter c: callback
    
        - returns: Returns itself for chaining operations
        
    */
    public func onComplete(_ ec: ExecutionContextType, _ c: @escaping Callback) -> Deferred {
        
        let callbackInContext = { result in
            ec.execute {
                c(result)
            }
        }
        
        callbacksManagingQueue.async {
            if let result = self.value {
                callbackInContext(result)
            } else {
                self.callbacks.append(callbackInContext)
            }
        }
        
        return self
    }

    // MARK:- Internal methods

    internal func setValue(_ value: T) {
        assert(self.value == nil, "Value can be set only once")
        
        callbacksManagingQueue.sync {
            
            self.value = value
            
            for callback in self.callbacks {
                callback(value)
            }
            
            self.callbacks.removeAll()
        }

    }

}
