//
//  Future.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import typealias Foundation.NSTimeInterval

// MARK:- future creation function

/**

    Creates a new `Future<T, E>` whose value will be
    result of execution `f` on background thread

    :param: f function, which result will become value of returned Future

    :returns: a new Future<T, E>
    
*/
public func future<T, E>(f: () -> Result<T, E>) -> Future<T, E> {
    return future(ExecutionContext.DefaultPureOperationContext, f)
}

/**

    Creates a new `Future<T, E>` whose value will be
    result of execution `f` on `ec` execution context

    :param: ec execution context of given function
    :param: f function, which result will become value of returned Future

    :returns: a new Future<T, E>
    
*/
public func future<T, E>(ec: ExecutionContextType, f: () -> Result<T, E>) -> Future<T, E> {
    let p = Promise<T, E>()
    
    ec.execute {
        p.complete(f())
    }
    
    return p.future
}

// MARK:- Future

/**

    Represents a value that will be available in the future

    This value is usually result of some computation or network request.

    May completes with either `Success` and `Error` cases

    This is convenient way to use `Deferred<Result<T, E>>`

    See also: `Deferred`

*/

public final class Future<T, E>: FutureType {
    
    // MARK:- Type declarations
    
    public typealias ResultType = Result<T, E>
    
    public typealias CompleteCallback = ResultType -> Void
    public typealias SuccessCallback = T -> Void
    public typealias ErrorCallback = E -> Void
    
    // MARK:- Private properties
    
    private let deferred: Deferred<ResultType>
    
    // MARK:- Public properties

    /// Value of Future
    public private(set) var value: ResultType? {
        set {
            deferred.setValue(newValue!)
        }
        get {
            return deferred.value
        }
    }

    /// Shows if Future is completed
    public var isCompleted: Bool {
        return deferred.isCompleted
    }
    
    // MARK:- Initialization
    
    internal init() {
        deferred = Deferred<ResultType>()
    }
    
    // MARK:- Class methods

    /**
    
        Returns a new immediately completed `Future<T, E>` with given `value`

        :param: value value which Future will have

        :returns: a new Future

    */
    public class func succeed(value: T) -> Future {
        return Future(.success(value))
    }


    /**

        Returns a new immediately completed `Future<T, E>` with given `error`

        :param: error error which Future will have

        :returns: a new Future
        
    */
    public class func failed(error: E) -> Future {
        return Future(.error(error))
    }
    
    // MARK:- FutureType methods

    /// Creates a new Future with given Result<T, E>
    public init(_ x: ResultType) {
        self.deferred = Deferred(x)
    }


    /**

        Register a callback which will be called when Future is completed

        :param: ec execution context of callback
        :param: c callback

        :returns: Returns itself for chaining operations
        
    */
    public func onComplete(ec: ExecutionContextType, _ c: CompleteCallback) -> Future {
        deferred.onComplete(ec, c)
        return self
    }


    /**

        Register a callback which will be called when Future is completed with value

        :param: ec execution context of callback
        :param: c callback

        :returns: Returns itself for chaining operations
        
    */
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
    
    /**

        Register a callback which will be called when Future is completed with error

        :param: ec execution context of callback
        :param: c callback

        :returns: Returns itself for chaining operations
        
    */
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
    
    /**

        Register a callback which will be called on a main thread when Future is completed

        :param: c callback

        :returns: Returns itself for chaining operations
        
    */
    public func onComplete(c: CompleteCallback) -> Future {
        return onComplete(ExecutionContext.DefaultSideEffectsContext, c)
    }
    
    /**

        Register a callback which will be called on a main thread when Future is completed with value

        :param: c callback

        :returns: Returns itself for chaining operations
        
    */
    public func onSuccess(c: SuccessCallback) -> Future {
        return onSuccess(ExecutionContext.DefaultSideEffectsContext, c)
    }
    
    /**

        Register a callback which will be called on a main thread when Future is completed with error

        :param: c callback

        :returns: Returns itself for chaining operations
        
    */
    public func onError(c: ErrorCallback) -> Future {
        return onError(ExecutionContext.DefaultSideEffectsContext, c)
    }
    
    
    // MARK:- Internal methods
    
    internal func setValue(value: ResultType) {
        self.value = value
    }
    
}

public extension Future {
    
    // MARK:- andThen
    
    /**

        Applies the side-effecting function that will be executed on main thread
        to the result of this future, and returns a new future with the result of this future

        :param: ec execution context of `f` function
        :param: f side-effecting function that will be applied to success result of future

        :returns: a new Future

    */
    public func andThen(f: T -> Void) -> Future {
        return PureFutures.andThen(f)(self)
    }
    
    /**

        Applies the side-effecting function to the success result of this future,
        and returns a new future with the result of this future

        :param: ec execution context of `f` function
        :param: f side-effecting function that will be applied to success result of future

        :returns: a new Future

    */
    public func andThen(ec: ExecutionContextType, f: T -> Void) -> Future {
        return PureFutures.andThen(f, ec)(self)
    }
    
    // MARK:- forced
    
    /**

        Stops the current thread, until value of future becomes available

        :returns: value of future

    */
    public func forced() -> ResultType {
        return PureFutures.forced(self)
    }
    
    /**

        Stops the currend thread, and wait for `inverval` seconds until value of future becoms available

        :param: inverval number of seconds to wait

        :returns: Value of future or nil if it hasn't become available yet

    */
    public func forced(interval: NSTimeInterval) -> ResultType? {
        return PureFutures.forced(interval)(self)
    }
    
    // MARK:- map
    
    /**

        Creates a new future by applying a function `f` that will be executed on global queue
        to the success result of this future.
    
        Do not put any UI-related code into `f` function

        :param: f Function that will be applied to success result of future

        :returns: a new Future

    */
    public func map<U>(f: T -> U) -> Future<U, E> {
        return PureFutures.map(f)(self)
    }
    
    /**

        Creates a new future by applying a function `f` to the success result of this future.

        :param: ec Execution context of `f`
        :param: f Function that will be applied to success result of future

        :returns: a new Future

    */
    public func map<U>(ec: ExecutionContextType, _ f: T -> U) -> Future<U, E> {
        return PureFutures.map(f, ec)(self)
    }
    
    // MARK:- transform
    
    /**

        Creates a new future by applying the 's' function to the successful result of this future, 
        or the 'e' function to the failed result.
    
        `s` and `e` will be executed on global queue
    
        Do not put any UI-related code into `s` and `e` functions

        :param: ec Execution context of `s` and `e` functions
        :param: s Function that will be applied to success result of the future
        :param: e Function that will be applied to failed result of the future

        :returns: a new Future
    */
    public func transform<T1, E1>(s: T -> T1, _ e: E -> E1) -> Future<T1, E1> {
        return PureFutures.transform(s, e)(self)
    }
    
    /**

        Creates a new future by applying the 's' function to the successful result of this future, 
        or the 'e' function to the failed result.

        :param: ec Execution context of `s` and `e` functions
        :param: s Function that will be applied to success result of the future
        :param: e Function that will be applied to failed result of the future

        :returns: a new Future
    */
    public func transform<T1, E1>(ec: ExecutionContextType, _ s: T -> T1, _ e: E -> E1) -> Future<T1, E1> {
        return PureFutures.transform(s, e, ec)(self)
    }
    
    // MARK:- flatMap
    
    /**

        Creates a new future by applying a function which will be executed on global queue
        to the success result of this future, and returns the result of the function as the new future.

        :param: f Funcion that will be applied to success result of the future

        :returns: a new Future

    */
    public func flatMap<U>(f: T -> Future<U, E>) -> Future<U, E> {
        return PureFutures.flatMap(f)(self)
    }
    
    /**

        Creates a new future by applying a function to the success result of this future, 
        and returns the result of the function as the new future.

        :param: ec Execution context of `f`
        :param: f Funcion that will be applied to success result of the future

        :returns: a new Future

    */
    public func flatMap<U>(ec: ExecutionContextType, _ f: T -> Future<U, E>) -> Future<U, E> {
        return PureFutures.flatMap(f, ec)(self)
    }
    
    // MARK:- flatten
    
    /**

        Removes one level of nesting of Future

        :param: fx Future

        :returns: flattened Future

    */
    public class func flatten(fx: Future<Future<T, E>, E>) -> Future {
        return PureFutures.flatten(fx)
    }
    
    // MARK:- filter
    
    /**

        Creates a new Future by filtering the value of the current Future with a predicate `p`
        which will be executed on global queue
    
        Do not put any UI-related code into `p` function

        :param: p Predicate function

        :returns: A new Future with value or nil

    */
    public func filter(p: T -> Bool) -> Future<T?, E> {
        return PureFutures.filter(p)(self)
    }
    
    /**

        Creates a new Future by filtering the value of the current Future with a predicate `p`

        :param: ec Execution context of `p`
        :param: p Predicate function

        :returns: A new Future with value or nil

    */
    public func filter(ec: ExecutionContextType, _ p: T -> Bool) -> Future<T?, E> {
        return PureFutures.filter(p, ec)(self)
    }
    
    // MARK:- zip
    
    /**

        Zips two future together and returns a new Future which success result contains a tuple of two elements

        :param: fx Another future

        :returns: Future with resuls of two futures

    */
    public func zip<U>(fx: Future<U, E>) -> Future<(T, U), E> {
        return PureFutures.zip(self, fx)
    }
    
    // MARK:- recover
    
    /**
        Creates a new future that will handle error value that this future might contain

        Returned future will never fail.
    
        `r` will be executed on global queue
    
        Do not put any UI-related code into `r` function
        
        See: `toDeferred`

        :param: ec Execution context of `r` function
        :param: r Recover function

        :returns: a new Future that will never fail

    */
    public func recover(r: E -> T) -> Future {
        return PureFutures.recover(r)(self)
    }
    
    /**
        Creates a new future that will handle error value that this future might contain

        Returned future will never fail.
        
        See: `toDeferred`

        :param: ec Execution context of `r` function
        :param: r Recover function

        :returns: a new Future that will never fail

    */
    public func recover(ec: ExecutionContextType, _ r: E -> T) -> Future {
        return PureFutures.recover(r, ec)(self)
    }
    
    // MARK:- recoverWith
    
    /**

        Creates a new future that will handle fail results that this future might contain by assigning it a value of another future.

        `r` will be executed on global queue
    
        Do not put any UI-related code into `r` function
    
        :param: ec Execition context of `r` function
        :param: r Recover function

        :returns: a new Future

    */
    public func recoverWith(r: E -> Future) -> Future {
        return PureFutures.recoverWith(r)(self)
    }
    
    /**

        Creates a new future that will handle fail results that this future might contain by assigning it a value of another future.

        :param: ec Execition context of `r` function
        :param: r Recover function

        :returns: a new Future

    */
    public func recoverWith(ec: ExecutionContextType, _ r: E -> Future) -> Future {
        return PureFutures.recoverWith(r, ec)(self)
    }
    
    // MARK:- toDeferred
    
    /**

        Transforms Future into Deferred

        :returns: Deferred

    */
    public func toDeferred() -> Deferred<Result<T, E>> {
        return deferred
    }
    
    /**

        Transforms Future<T, E> into Deferred<T> and handles error case with `r` function
        which will be executed on global queue
    
        Do not put any UI-related code into `r` function

        :param: ec Execution context of `r` function
        :param: r Recover function

        :returns: Deferred with success value of `fx` or result of `r`

    */
    public func toDeferred(r: E -> T) -> Deferred<T> {
        return PureFutures.toDeferred(r)(self)
    }
    
    /**

        Transforms Future<T, E> into Deferred<T> and handles error case with `r` function

        :param: ec Execution context of `r` function
        :param: r Recover function

        :returns: Deferred with success value of `fx` or result of `r`

    */
    public func toDeferred(ec: ExecutionContextType, _ r: E -> T) -> Deferred<T> {
        return PureFutures.toDeferred(r, ec)(self)
    }
    
    // MARK:- reduce
    
    /**

        Reduces the elements of sequence of futures using the specified reducing function `combine`
        which will be executed on global queue

        Do not put any UI-related code into `combine` function

        :param: ec Execution context of `combine`
        :param: fxs Sequence of Futures
        :param: initial Initial value that will be passed as first argument in `combine` function
        :param: combine reducing function

        :returns: Future which will contain result of reducing sequence of futures

    */
    public class func reduce<U>(fxs: [Future], _ initial: U, _ combine: (U, T) -> U) -> Future<U, E> {
        return PureFutures.reduce(initial, combine)(fxs)
    }
    
    /**

        Reduces the elements of sequence of futures using the specified reducing function `combine`

        :param: ec Execution context of `combine`
        :param: fxs Sequence of Futures
        :param: initial Initial value that will be passed as first argument in `combine` function
        :param: combine reducing function

        :returns: Future which will contain result of reducing sequence of futures

    */
    public class func reduce<U>(ec: ExecutionContextType, _ fxs: [Future], _ initial: U, _ combine: (U, T) -> U) -> Future<U, E> {
        return PureFutures.reduce(initial, combine, ec)(fxs)
    }
    
    // MARK:- traverse
    
    /**

        Transforms an array of values into Future of array of this values using the provided function `f`
        which will be executed on global queue
    
        Do not put any UI-related code into `f` function

        :param: ec Execution context of `f`
        :param: xs Sequence of values
        :param: f Function for transformation values into Future

        :returns: a new Future

    */
    public class func traverse<U>(xs: [T], _ f: T -> Future<U, E>) -> Future<[U], E> {
        return PureFutures.traverse(f)(xs)
    }
    
    /**

        Transforms an array of values into Future of array of this values using the provided function `f`

        :param: ec Execution context of `f`
        :param: xs Sequence of values
        :param: f Function for transformation values into Future

        :returns: a new Future

    */
    public class func traverse<U>(ec: ExecutionContextType, _ xs: [T], _ f: T -> Future<U, E>) -> Future<[U], E> {
        return PureFutures.traverse(f, ec)(xs)
    }
    
    // MARK:- sequence
    
    /**

        Transforms a sequnce of Futures into Future of array of values

        :param: fxs Sequence of Futures

        :returns: Future with array of values

    */
    public class func sequence(fxs: [Future]) -> Future<[T], E> {
        return PureFutures.sequence(fxs)
    }
    
}
