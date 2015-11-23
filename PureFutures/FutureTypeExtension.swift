//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import typealias Foundation.NSTimeInterval
import enum Result.Result

// MARK: - Operators

/**

    Transforms Future to Deferred using future's success value or `x` in case when future was completed with error

    - parameter fx: Future
    - parameter x: recover value

    - returns: Deferred

*/
public func ??<F: FutureType>(fx: F, x: F.Success) -> Deferred<F.Success> {
    return fx.toDeferred(r: constant(x))
}

/**

    Recovers future with another future.

    see: `recoverWith`

    - parameter fx: Future
    - parameter x: future which value will be used if `fx` fails

    - returns: a new Future

*/
public func ??<F: FutureType>(fx: F, x: F) -> Future<F.Success, F.Error> {
    return fx.recoverWith(Pure, r: constant(x))
}

// MARK: - Extension

extension FutureType {
    
    /**

        Applies the side-effecting function to the success result of this future,
        and returns a new future with the result of this future

        - parameter ec: execution context of `f` function. By default is main queue
        - parameter f: side-effecting function that will be applied to result of `fx`

        - returns: a new Future

    */
    public func andThen(ec: ExecutionContextType = SideEffects, f: Success -> Void) -> Future<Success, Error> {
        let p = Promise<Success, Error>()
        
        onComplete(ec) {
            switch $0 {
            case .Success(let value):
                p.success(value)
                f(value)
            case .Failure(let error):
                p.error(error)
            }
        }
        
        return p.future
    }
    
    /**

        Creates a new future by applying a function `f` to the success result of this future.

        - parameter ec: Execution context of `f`. By default is global queue
        - parameter f: Function that will be applied to success result of `fx`

        - returns: a new Future

    */
    public func map<T>(ec: ExecutionContextType = Pure, f: Success -> T) -> Future<T, Error> {
        return transform(ec, s: f, e: identity)
    }
    
    /**

        Creates a new future by applying the 's' function to the successful result of this future, or the 'e' function to the failed result.

        - parameter ec: Execution context of `s` and `e` functions. By default is global queue
        - parameter s: Function that will be applied to success result of `fx`
        - parameter e: Function that will be applied to failed result of `fx`

        - returns: a new Future
    */
    public func transform<S, E: ErrorType>(ec: ExecutionContextType = Pure, s: Success -> S, e: Error -> E) -> Future<S, E> {
        let p = Promise<S, E>()
        
        onComplete(ec) {
            switch $0 {
            case .Success(let value):
                p.success(s(value))
            case .Failure(let error):
                p.error(e(error))
            }
        }
        
        return p.future
    }
    
    
    /**

        Creates a new future by applying a function to the success result of this future, and returns the result of the function as the new future.

        - parameter ec: Execution context of `f`. By default is global queue
        - parameter f: Funcion that will be applied to success result of `fx`

        - returns: a new Future

    */
    public func flatMap<F: FutureType where F.Error == Error>(ec: ExecutionContextType = Pure, f: Success -> F) -> Future<F.Success, Error> {
        let p = Promise<F.Success, Error>()
        
        onComplete(ec) {
            switch $0 {
            case .Success(let value):
                p.completeWith(f(value))
            case .Failure(let error):
                p.error(error)
            }
        }
        
        return p.future
    }
    
    /**

        Creates a new Future by filtering the value of the current Future with a predicate `p`

        - parameter ec: Execution context of `p`. By default is global queue
        - parameter p: Predicate function

        - returns: A new Future with value or nil

    */
    public func filter(ec: ExecutionContextType = Pure, p: Success -> Bool) -> Future<Success?, Error> {
        return map(ec) { x in p(x) ? x : nil }
    }

    /**

        Zips with another future and returns a new Future which success result contains a tuple of two elements

        - parameter x: Another future

        - returns: Future with resuls of two futures
    */
    public func zip<F: FutureType where F.Error == Error>(x: F) -> Future<(Success, F.Success), Error> {
        
        let ec = Pure
        
        return flatMap(ec) { a in
            x.map(ec) { b in
                (a, b)
            }
        }
    }

    /**
        Creates a new future that will handle error value that this future might contain

        Returned future will never fail.
        
        See: `toDeferred`

        - parameter ec: Execution context of `r` function. By default is global queue
        - parameter r: Recover function

        - returns: a new Future that will never fail

    */
    public func recover(ec: ExecutionContextType = Pure, r: Error -> Success) -> Future<Success, Error> {
        let p = Promise<Success, Error>()
        
        onComplete(ec) {
            switch $0 {
            case .Success(let value):
                p.success(value)
            case .Failure(let error):
                p.success(r(error))
            }
        }
        
        return p.future
    }

    /**

        Creates a new future that will handle fail results that this future might contain by assigning it a value of another future.

        - parameter ec: Execition context of `r` function. By default is global queue
        - parameter r: Recover function

        - returns: a new Future

    */
    public func recoverWith(ec: ExecutionContextType = Pure, r: Error -> Self) -> Future<Success, Error> {
        let p = Promise<Success, Error>()
        onComplete(ec) {
            switch $0 {
            case .Success(let value):
                p.success(value)
            case .Failure(let error):
                p.completeWith(r(error))
            }
        }
        return p.future
    }

    /**

        Transforms Future<T, E> into Deferred<Result<T, E>>

        - returns: Deferred

    */
    public func toDeferred() -> Deferred<Result<Success, Error>> {
        let p = PurePromise<Result<Success, Error>>()
        onComplete(Pure) {
            p.complete($0)
        }
        return p.deferred
    }

    /**

        Transforms Future<T, E> into Deferred<T> and handles error case with `r` function

        - parameter ec: Execution context of `r` function. By default is global queue
        - parameter r: Recover function

        - returns: Deferred with success value of `fx` or result of `r`

    */
    public func toDeferred(ec: ExecutionContextType = Pure, r: Error -> Success) -> Deferred<Success> {
        let p = PurePromise<Success>()
        onComplete(ec) {
            switch $0 {
            case .Success(let value):
                p.complete(value)
            case .Failure(let error):
                p.complete(r(error))
            }
        }
        return p.deferred
    }
}

// MARK: - Nested FutureType extension

extension FutureType where Success: FutureType, Success.Error == Error {
    
    /**

        Converts Future<Future<S, E>, E> into Future<S, E>

        - returns: flattened Future

    */
    public func flatten() -> Future<Success.Success, Error> {
        let p = Promise<Success.Success, Error>()
        
        onComplete(Pure) {
            switch $0 {
            case .Success(let future):
                p.completeWith(future)
            case .Failure(let error):
                p.error(error)
            }
        }
        
        return p.future
    }
    
    
}

// MARK: - Sequence Extensions

extension SequenceType where Generator.Element: FutureType {
    
    /**

        Reduces the elements of sequence of futures using the specified reducing function `combine`

        - parameter ec: Execution context of `combine`. By default is global queue
        - parameter initial: Initial value that will be passed as first argument in `combine` function
        - parameter combine: reducing function

        - returns: Future which will contain result of reducing sequence of futures

    */
    public func reduce<T>(ec: ExecutionContextType = Pure, initial: T, combine: (T, Generator.Element.Success) -> T) -> Future<T, Generator.Element.Error> {
        return reduce(.succeed(initial)) { acc, future in
            future.flatMap(ec) { value in
                acc.map(ec) {
                    combine($0, value)
                }
            }
        }
    }
    
    /**

        Transforms a sequnce of Futures into Future of array of values:

        [Future<T, E>] -> Future<[T], E>

        - returns: Future with array of values

    */
    public func sequence() -> Future<[Generator.Element.Success], Generator.Element.Error> {
        return traverse(Pure, f: identity)
    }

}

extension SequenceType {
    
    /**

        Transforms a sequence of values into Future of array of this values using the provided function `f`

        - parameter ec: Execution context of `f`. By default is global queue
        - parameter f: Function for transformation values into Future

        - returns: a new Future

    */
    public func traverse<F: FutureType>(ec: ExecutionContextType = Pure, f: Generator.Element -> F) -> Future<[F.Success], F.Error> {
        // TODO: Replace $0 + [$1] with the more efficien impl
        return map(f).reduce(ec, initial: []) { $0 + [$1] }
    }
    
}
