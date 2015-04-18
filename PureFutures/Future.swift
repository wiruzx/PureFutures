//
//  Future.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

// MARK:- future creation function

// MARK: With Result<T, E>

public func future<T, E>(@autoclosure f: () -> Result<T, E>) -> Future<T, E> {
    let x = f()
    return future { x }
}

public func future<T, E>(f: () -> Result<T, E>) -> Future<T, E> {
    return future(ExecutionContext.DefaultPureOperationContext, f)
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
    
    public func onComplete(ec: ExecutionContextType, _ c: CompleteCallback) -> Future {
        deferred.onComplete(ec, c)
        return self
    }
    
    public func onSuccess(ec: ExecutionContextType, _ c: SuccessCallback) -> Future {
        return onComplete(ec) {
            switch $0 {
            case .Success(let boxed):
                c(boxed.value)
            default:
                break
            }
        }
    }
    
    public func onError(ec: ExecutionContextType, _ c: ErrorCallback) -> Future {
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
        return onComplete(ExecutionContext.DefaultSideEffectsContext, c)
    }
    
    public func onSuccess(c: SuccessCallback) -> Future {
        return onSuccess(ExecutionContext.DefaultSideEffectsContext, c)
    }
    
    public func onError(c: ErrorCallback) -> Future {
        return onError(ExecutionContext.DefaultSideEffectsContext, c)
    }
    
}

public extension Future {
    
    // MARK:- Convenience methods
    
    public func andThen(f: T -> Void) -> Future {
        return andThen(ExecutionContext.DefaultSideEffectsContext, f: f)
    }
    
    public func map<U>(f: T -> U) -> Future<U, E> {
        return map(ExecutionContext.DefaultPureOperationContext, f)
    }
    
    public func transform<T1, E1>(s: T -> T1, _ e: E -> E1) -> Future<T1, E1> {
        return transform(ExecutionContext.DefaultPureOperationContext, s, e)
    }
    
    public func flatMap<U>(f: T -> Future<U, E>) -> Future<U, E> {
        return flatMap(ExecutionContext.DefaultPureOperationContext, f)
    }
    
    public func filter(p: T -> Bool) -> Future<T?, E> {
        return filter(ExecutionContext.DefaultPureOperationContext, p)
    }
    
    public func recover(r: E -> T) -> Future {
        return recover(ExecutionContext.DefaultPureOperationContext, r)
    }
    
    public func recoverWith(r: E -> Future) -> Future {
        return recoverWith(ExecutionContext.DefaultPureOperationContext, r)
    }
    
    public func toDeferred(r: E -> T) -> Deferred<T> {
        return toDeferred(ExecutionContext.DefaultPureOperationContext, r)
    }
    
    public class func reduce<U>(fxs: [Future], _ initial: U, _ combine: (U, T) -> U) -> Future<U, E> {
        return reduce(ExecutionContext.DefaultPureOperationContext, fxs, initial, combine)
    }
    
    public class func traverse<U>(xs: [T], _ f: T -> Future<U, E>) -> Future<[U], E> {
        return traverse(ExecutionContext.DefaultPureOperationContext, xs, f)
    }
    
    // MARK:- Original methods
    
    public func andThen(ec: ExecutionContextType, f: T -> Void) -> Future {
        return PureFutures.andThen(self, f)(ec)
    }
    
    public func forced() -> ResultType {
        return PureFutures.forced(self)
    }
    
    public func forced(interval: NSTimeInterval) -> ResultType? {
        return PureFutures.forced(self, interval)
    }
    
    public func map<U>(ec: ExecutionContextType, _ f: T -> U) -> Future<U, E> {
        return PureFutures.map(self, f)(ec)
    }
    
    public func transform<T1, E1>(ec: ExecutionContextType, _ s: T -> T1, _ e: E -> E1) -> Future<T1, E1> {
        return PureFutures.transform(self, s, e)(ec)
    }
    
    public func flatMap<U>(ec: ExecutionContextType, _ f: T -> Future<U, E>) -> Future<U, E> {
        return PureFutures.flatMap(self, f)(ec)
    }
    
    public func filter(ec: ExecutionContextType, _ p: T -> Bool) -> Future<T?, E> {
        return PureFutures.filter(self, p)(ec)
    }
    
    public func zip<U>(fx: Future<U, E>) -> Future<(T, U), E> {
        return PureFutures.zip(self, fx)
    }
    
    public func recover(ec: ExecutionContextType, _ r: E -> T) -> Future {
        return PureFutures.recover(self, r)(ec)
    }
    
    public func recoverWith(ec: ExecutionContextType, _ r: E -> Future) -> Future {
        return PureFutures.recoverWith(self, r)(ec)
    }
    
    public func toDeferred() -> Deferred<Result<T, E>> {
        return PureFutures.toDeferred(self)
    }
    
    public func toDeferred(ec: ExecutionContextType, _ r: E -> T) -> Deferred<T> {
        return PureFutures.toDeferred(self, r)(ec)
    }
    
    public class func flatten(fx: Future<Future<T, E>, E>) -> Future {
        return PureFutures.flatten(fx)
    }
    
    public class func reduce<U>(ec: ExecutionContextType, _ fxs: [Future], _ initial: U, _ combine: (U, T) -> U) -> Future<U, E> {
        return PureFutures.reduce(fxs, initial, combine)(ec)
    }
    
    public class func traverse<U>(ec: ExecutionContextType, _ xs: [T], _ f: T -> Future<U, E>) -> Future<[U], E> {
        return PureFutures.traverse(xs, f)(ec)
    }
    
    public class func sequence(fxs: [Future]) -> Future<[T], E> {
        return PureFutures.sequence(fxs)
    }
    
}
