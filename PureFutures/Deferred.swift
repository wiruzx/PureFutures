//
//  Deferred.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class Deferred<T>: DeferredType {
    
    // MARK:- Type declarations
    
    public typealias Callback = T -> Void
    
    // MARK:- Private properties
    
    private var callbacks: [Callback] = []
    
    // MARK:- Internal properties
    
    internal var result: T? {
        didSet {
            assert(oldValue == nil, "Cannot complete Deferred more than once")
            assert(result != nil, "Result can't be nil")
            
            for callback in callbacks {
                callback(result!)
            }
            
            callbacks.removeAll()
        }
    }
    
    // MARK:- Public properties
    
    public var value: T? {
        return result
    }
    
    // MARK:- Initialization
    
    internal init() {
        
    }
    
    public init(_ f: () -> T) {
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            self.result = f()
        }
    }
    
    public convenience init(_ f: @autoclosure () -> T) {
        self.init(f as () -> T)
    }
    
    // MARK:- DeferredType methods
    
    public class func completed(value: T) -> Deferred {
        let d = Deferred()
        
        d.result = value
        
        return d
    }
    
    public func onComplete(c: Callback) -> Deferred {
        
        if let result = result {
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
        return map { value in p(value) ? value : nil }
    }
    
}
