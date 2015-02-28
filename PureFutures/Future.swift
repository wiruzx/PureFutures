//
//  Future.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func future<T, E>(f: @autoclosure () -> T) -> Future<T, E> {
    return future(f as () -> T)
}

public func future<T, E>(f: () -> T) -> Future<T, E> {
    let p = Promise<T, E>()
    p.success(f())
    return p.future
}

public final class Future<T, E>: FutureType {
    
    // MARK:- Type declarations
    
    public typealias CompleteCallback = Result<T, E> -> Void
    public typealias SuccessCallback = T -> Void
    public typealias ErrorCallback = E -> Void
    
    // MARK:- Private properties
    
    private let deferred = Deferred<Result<T, E>>()
    
    // MARK:- Public properties
    
    public internal(set) var value: Result<T, E>? {
        set {
            deferred.value = newValue
        }
        get {
            return deferred.value
        }
    }
    
    // MARK:- Initialization
    
    internal init() {
    }
    
    // MARK:- Class methods
    
    public class func succeed(value: T) -> Future {
        return Future(Result(value))
    }
    
    public class func failed(error: E) -> Future {
        return Future(Result(error))
    }
    
    // MARK:- FutureType methods
    
    public init(_ x: Result<T, E>) {
        self.deferred = Deferred(x)
    }
    
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
    
    public func onError(c: ErrorCallback) -> Future {
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
        return PureFutures.map(self, f)
    }
    
    public func flatMap<U>(f: T -> Future<U, E>) -> Future<U, E> {
        return PureFutures.flatMap(self, f)
    }
    
    public func filter(p: T -> Bool) -> Future<T?, E> {
        return PureFutures.filter(self, p)
    }
    
    public func zip<U>(fx: Future<U, E>) -> Future<(T, U), E> {
        return PureFutures.zip(self, fx)
    }
    
    public func recover(r: E -> T) -> Future {
        return PureFutures.recover(self, r)
    }
    
    public func recoverWith(r: E -> Future) -> Future {
        return PureFutures.recoverWith(self, r)
    }
    
    public class func reduce<U>(fxs: [Future], initial: U, combine: (U, T) -> U) -> Future<U, E> {
        return PureFutures.reduce(fxs, initial, combine)
    }
    
    public class func traverse<U>(xs: [T], f: T -> Future<U, E>) -> Future<[U], E> {
        return PureFutures.traverse(xs, f)
    }
    
    public class func sequence(fxs: [Future]) -> Future<[T], E> {
        return PureFutures.sequence(fxs)
    }
    
}
