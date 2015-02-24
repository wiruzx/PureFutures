//
//  Future.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class Future<T, E>: FutureType {
    
    typealias SuccessType = T
    typealias FailureType = E
    
    // MARK:- Type declarations
    
    public typealias CompleteCallback = Result<T, E> -> Void
    public typealias SuccessCallback = T -> Void
    public typealias FailureCallback = E -> Void
    
    // MARK:- Private properties
    
    internal let deferred = Deferred<Result<T, E>>()
    
    // MARK:- Public properties
    
    public var value: Result<T, E>? {
        return deferred.value
    }
    
    // MARK:- Initialization
    
    internal init() {
    }
    
    internal init(deferred: Deferred<Result<T, E>>) {
        self.deferred = deferred
    }
    
    // MARK:- Public methods
    
    public func onComplete(c: CompleteCallback) -> Future {
        deferred.onComplete(c)
        return self
    }
    
    public func onSuccess(c: SuccessCallback) -> Future {
        return onComplete {
            switch $0 {
            case .Success(let boxed):
                c(boxed.value)
            default:
                break
            }
        }
    }
    
    public func onFailure(c: FailureCallback) -> Future {
        return onComplete {
            switch $0 {
            case .Error(let boxed):
                c(boxed.value)
            default:
                break
            }
        }
    }
}

public extension Future {
    
    public func map<U>(f: T -> U) -> Future<U, E> {
        return flatMap { value  in
            return Future<U, E>(deferred: Deferred.completed(.Success(Box(f(value)))))
        }
    }
    
    public func flatMap<U>(f: T -> Future<U, E>) -> Future<U, E> {
        let p = Promise<Result<U, E>>()
        
        onComplete {
            switch $0 {
            case .Success(let boxed):
                p.completeWith(f(boxed.value).deferred)
            case .Error(let boxed):
                p.complete(.Error(Box(boxed.value)))
            }
        }
        
        return Future<U, E>(deferred: p.deferred)
    }
    
    public func mapResult<U>(f: T -> Result<U, E>) -> Future<U, E> {
        return Future<U, E>(deferred: deferred.map { $0.flatMap(f) })
    }
    
    public func filter(p: T -> Bool) -> Future<T?, E> {
        return map { value in p(value) ? value : nil }
    }
    
}
