//
//  Future.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

// MARK:- future creation function

public func future<T, E>(@autoclosure f: () -> Result<T, E>) -> Future<T, E> {
    return future(f)
}

public func future<T, E>(f: () -> Result<T, E>) -> Future<T, E> {
    return future(defaultContext, f)
}

public func future<T, E>(ec: ExecutionContextType, f: () -> Result<T, E>) -> Future<T, E> {
    let p = Promise<T, E>()
    
    ec.execute {
        p.complete(f())
    }
    
    return p.future
}

// MARK:- Future

public final class Future<T, E>: FutureType {
    
    // MARK:- Type declarations
    
    public typealias ResultType = Result<T, E>
    
    public typealias CompleteCallback = ResultType -> Void
    public typealias SuccessCallback = T -> Void
    public typealias ErrorCallback = E -> Void
    
    // MARK:- Private properties
    
    private let deferred: Deferred<ResultType>
    
    // MARK:- Public properties
    
    public internal(set) var value: ResultType? {
        set {
            deferred.setValue(newValue)
        }
        get {
            return deferred.value
        }
    }
    
    // MARK:- Initialization
    
    internal init() {
        deferred = Deferred<ResultType>()
    }
    
    // MARK:- Class methods
    
    public class func succeed(value: T) -> Future {
        return Future(Result(value))
    }
    
    public class func failed(error: E) -> Future {
        return Future(Result(error))
    }
    
    // MARK:- FutureType methods
    
    public init(_ x: ResultType) {
        self.deferred = Deferred(x)
    }
    
    public func onComplete(ec: ExecutionContextType, c: CompleteCallback) -> Future {
        deferred.onComplete(ec, c: c)
        return self
    }
    
    public func onSuccess(ec: ExecutionContextType, c: SuccessCallback) -> Future {
        return onComplete(ec) {
            switch $0 {
            case .Success(let boxed):
                c(boxed.value)
            default:
                break
            }
        }
    }
    
    public func onError(ec: ExecutionContextType, c: ErrorCallback) -> Future {
        return onComplete(ec) {
            switch $0 {
            case .Error(let boxed):
                c(boxed.value)
            default:
                break
            }
        }
    }
    
    // MARK:- Convenience methods
    
    public func onComplete(c: CompleteCallback) -> Future {
        return onComplete(defaultContext, c: c)
    }
    
    public func onSuccess(c: SuccessCallback) -> Future {
        return onSuccess(defaultContext, c: c)
    }
    
    public func onError(c: ErrorCallback) -> Future {
        return onError(defaultContext, c: c)
    }
    
}

public extension Future {
    
    // MARK:- Convenience methods
    
    public func andThen(f: T -> Void) -> Future {
        return andThen(defaultContext, f: f)
    }
    
    public func map<U>(f: T -> U) -> Future<U, E> {
        return map(defaultContext, f: f)
    }
    
    public func transform<T1, E1>(s: T -> T1, e: E -> E1) -> Future<T1, E1> {
        return transform(defaultContext, s: s, e: e)
    }
    
    public func flatMap<U>(f: T -> Future<U, E>) -> Future<U, E> {
        return flatMap(defaultContext, f: f)
    }
    
    public func filter(p: T -> Bool) -> Future<T?, E> {
        return filter(defaultContext, p: p)
    }
    
    public func zip<U>(fx: Future<U, E>) -> Future<(T, U), E> {
        return zip(defaultContext, fx: fx)
    }
    
    public func recover(r: E -> T) -> Future {
        return recover(defaultContext, r: r)
    }
    
    public func recoverWith(r: E -> Future) -> Future {
        return recoverWith(defaultContext, r: r)
    }
    
    public func toDeferred() -> Deferred<Result<T, E>> {
        return toDeferred(defaultContext)
    }
    
    public func toDeferred(r: E -> T) -> Deferred<T> {
        return toDeferred(defaultContext, r: r)
    }
    
    public class func reduce<U>(fxs: [Future], initial: U, combine: (U, T) -> U) -> Future<U, E> {
        return reduce(defaultContext, fxs: fxs, initial: initial, combine: combine)
    }
    
    public class func traverse<U>(xs: [T], f: T -> Future<U, E>) -> Future<[U], E> {
        return traverse(defaultContext, xs: xs, f: f)
    }
    
    public class func sequence(fxs: [Future]) -> Future<[T], E> {
        return sequence(defaultContext, fxs: fxs)
    }
    
    // MARK:- Original methods
    
    public func andThen(ec: ExecutionContextType, f: T -> Void) -> Future {
        return PureFutures.andThen(self, f)(ec: ec)
    }
    
    public func forced() -> ResultType {
        return PureFutures.forced(self)
    }
    
    public func forced(interval: NSTimeInterval) -> ResultType? {
        return PureFutures.forced(self, interval)
    }
    
    public func map<U>(ec: ExecutionContextType, f: T -> U) -> Future<U, E> {
        return PureFutures.map(self, f)(ec: ec)
    }
    
    public func transform<T1, E1>(ec: ExecutionContextType, s: T -> T1, e: E -> E1) -> Future<T1, E1> {
        return PureFutures.transform(self, s, e)(ec: ec)
    }
    
    public func flatMap<U>(ec: ExecutionContextType, f: T -> Future<U, E>) -> Future<U, E> {
        return PureFutures.flatMap(self, f)(ec: ec)
    }
    
    public func filter(ec: ExecutionContextType, p: T -> Bool) -> Future<T?, E> {
        return PureFutures.filter(self, p)(ec: ec)
    }
    
    public func zip<U>(ec: ExecutionContextType, fx: Future<U, E>) -> Future<(T, U), E> {
        return PureFutures.zip(self, fx)(ec: ec)
    }
    
    public func recover(ec: ExecutionContextType, r: E -> T) -> Future {
        return PureFutures.recover(self, r)(ec: ec)
    }
    
    public func recoverWith(ec: ExecutionContextType, r: E -> Future) -> Future {
        return PureFutures.recoverWith(self, r)(ec: ec)
    }
    
    public func toDeferred(ec: ExecutionContextType) -> Deferred<Result<T, E>> {
        return PureFutures.toDeferred(self)(ec: ec)
    }
    
    public func toDeferred(ec: ExecutionContextType, r: E -> T) -> Deferred<T> {
        return PureFutures.toDeferred(self, r)(ec: ec)
    }
    
    public class func reduce<U>(ec: ExecutionContextType, fxs: [Future], initial: U, combine: (U, T) -> U) -> Future<U, E> {
        return PureFutures.reduce(fxs, initial, combine)(ec: ec)
    }
    
    public class func traverse<U>(ec: ExecutionContextType, xs: [T], f: T -> Future<U, E>) -> Future<[U], E> {
        return PureFutures.traverse(xs, f)(ec: ec)
    }
    
    public class func sequence(ec: ExecutionContextType, fxs: [Future]) -> Future<[T], E> {
        return PureFutures.sequence(fxs)(ec: ec)
    }
    
}
