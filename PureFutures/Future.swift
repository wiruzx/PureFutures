//
//  Future.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

// MARK:- future creation function

public func future<T, E>(f: @autoclosure () -> T) -> Future<T, E> {
    return future(defaultContext, f)
}

public func future<T, E>(ec: ExecutionContextType, f: @autoclosure () -> T) -> Future<T, E> {
    return future(f as () -> T)
}


public func future<T, E>(f: () -> T) -> Future<T, E> {
    return future(defaultContext, f)
}

public func future<T, E>(ec: ExecutionContextType, f: () -> T) -> Future<T, E> {
    let p = Promise<T, E>()
    ec.execute {
        p.success(f())
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
    
    private let deferred = Deferred<ResultType>()
    
    // MARK:- Public properties
    
    public internal(set) var value: ResultType? {
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
    
    public init(_ x: ResultType) {
        self.deferred = Deferred(x)
    }
    
    public func onComplete(ec: ExecutionContextType, c: CompleteCallback) -> Future {
        deferred.onComplete(ec, c)
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
    
    public func forced() -> ResultType {
        return PureFutures.forced(self)
    }
    
    public func forced(interval: NSTimeInterval) -> ResultType? {
        return PureFutures.forced(self, interval)
    }
    
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
    
    // MARK:- With execution context
    
    public func forced(ec: ExecutionContextType) -> ResultType {
        return PureFutures.forced(ec, self)
    }
    
    public func forced(ec: ExecutionContextType, interval: NSTimeInterval) -> ResultType? {
        return PureFutures.forced(ec, self, interval)
    }
    
    public func map<U>(ec: ExecutionContextType, f: T -> U) -> Future<U, E> {
        return PureFutures.map(ec, self, f)
    }
    
    public func flatMap<U>(ec: ExecutionContextType, f: T -> Future<U, E>) -> Future<U, E> {
        return PureFutures.flatMap(ec, self, f)
    }
    
    public func filter(ec: ExecutionContextType, p: T -> Bool) -> Future<T?, E> {
        return PureFutures.filter(ec, self, p)
    }
    
    public func zip<U>(ec: ExecutionContextType, fx: Future<U, E>) -> Future<(T, U), E> {
        return PureFutures.zip(ec, self, fx)
    }
    
    public func recover(ec: ExecutionContextType, r: E -> T) -> Future {
        return PureFutures.recover(ec, self, r)
    }
    
    public func recoverWith(ec: ExecutionContextType, r: E -> Future) -> Future {
        return PureFutures.recoverWith(ec, self, r)
    }
    
    public class func reduce<U>(ec: ExecutionContextType, fxs: [Future], initial: U, combine: (U, T) -> U) -> Future<U, E> {
        return PureFutures.reduce(ec, fxs, initial, combine)
    }
    
    public class func traverse<U>(ec: ExecutionContextType, xs: [T], f: T -> Future<U, E>) -> Future<[U], E> {
        return PureFutures.traverse(ec, xs, f)
    }
    
    public class func sequence(ec: ExecutionContextType, fxs: [Future]) -> Future<[T], E> {
        return PureFutures.sequence(ec, fxs)
    }
    
}
