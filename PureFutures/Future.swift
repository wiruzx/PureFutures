//
//  Future.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class Future<T, E> {
    
    public typealias CompleteCallback = Result<T, E> -> Void
    public typealias SuccessCallback = T -> Void
    public typealias FailureCallback = E -> Void
    
    // MARK:- Private properties
    
    private let deferred = Deferred<Result<T, E>>()
    
    // MARK:- Internal properties
    
    internal var result: Result<T, E>? {
        set {
            deferred.result = newValue
        }
        get {
            return deferred.result
        }
    }
    
    // MARK:- Public properties
    
    public var value: Result<T, E>? {
        return result
    }
    
    // MARK:- Initialization
    
    internal init() {
    }
    
    private init(deferred: Deferred<Result<T, E>>) {
        self.deferred = deferred
    }
    
    // MARK:- Public methods
    
    // MARK: Instance methods
    
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
    
    // MARK: Class methods
    
    public class func succeed(value: T) -> Future<T, E> {
        return Future(deferred: Deferred.completed(.Success(Box(value))))
    }
    
    public class func failed(error: E) -> Future<T, E> {
        return Future(deferred: Deferred.completed(.Error(Box(error))))
    }
}

public extension Future {
    
    public func map<U>(f: T -> U) -> Future<U, E> {
        return flatMap { value  in
            return Future<U, E>.succeed(f(value))
        }
    }
    
    public func flatMap<U>(f: T -> Future<U, E>) -> Future<U, E> {
        let p = FailablePromise<U, E>()
        
        onComplete {
            switch $0 {
            case .Success(let boxed):
                p.completeWith(f(boxed.value))
            case .Error(let boxed):
                p.failure(boxed.value)
            }
        }
        
        return p.future
    }
    
    public func mapResult<U>(f: T -> Result<U, E>) -> Future<U, E> {
        return Future<U, E>(deferred: deferred.map { $0.flatMap(f) })
    }
    
    public func filter(p: T -> Bool) -> Future<T?, E> {
        return map { value in p(value) ? value : nil }
    }
    
}
