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
public func ??<F: FutureType>(fx: F, x: F.Value.Value) -> Deferred<F.Value.Value> {
    return fx.toDeferred(r: constant(x))
}

/**

    Recovers future with another future.

    see: `recoverWith`

    - parameter fx: Future
    - parameter x: future which value will be used if `fx` fails

    - returns: a new Future

*/
public func ??<F: FutureType>(fx: F, x: F) -> Future<F.Value.Value, F.Value.Error> {
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
    public func andThen(ec: ExecutionContextType = SideEffects, f: Value.Value -> Void) -> Future<Value.Value, Value.Error> {
        let p = Promise<Value.Value, Value.Error>()
        
        onComplete(ec) { result in
            result.analysis(ifSuccess: { value in
                p.success(value)
                f(value)
            }, ifFailure: { error in
                p.error(error)
            })
        }
        
        return p.future
    }
    
    /**

        Creates a new future by applying a function `f` to the success result of this future.

        - parameter ec: Execution context of `f`. By default is global queue
        - parameter f: Function that will be applied to success result of `fx`

        - returns: a new Future

    */
    public func map<T>(ec: ExecutionContextType = Pure, f: Value.Value -> T) -> Future<T, Value.Error> {
        return transform(ec, s: f, e: identity)
    }
    
    /**

        Creates a new future by applying the 's' function to the successful result of this future, or the 'e' function to the failed result.

        - parameter ec: Execution context of `s` and `e` functions. By default is global queue
        - parameter s: Function that will be applied to success result of `fx`
        - parameter e: Function that will be applied to failed result of `fx`

        - returns: a new Future
    */
    public func transform<S, E: ErrorType>(ec: ExecutionContextType = Pure, s: Value.Value -> S, e: Value.Error -> E) -> Future<S, E> {
        let p = Promise<S, E>()
        
        onComplete(ec) { result in
            result.analysis(ifSuccess: { value in
                p.success(s(value))
            }, ifFailure: { error in
                p.error(e(error))
            })
        }
        
        return p.future
    }
    
    
    /**

        Creates a new future by applying a function to the success result of this future, and returns the result of the function as the new future.

        - parameter ec: Execution context of `f`. By default is global queue
        - parameter f: Funcion that will be applied to success result of `fx`

        - returns: a new Future

    */
    public func flatMap<F: FutureType where F.Value.Error == Value.Error>(ec: ExecutionContextType = Pure, f: Value.Value -> F) -> Future<F.Value.Value, Value.Error> {
        let p = Promise<F.Value.Value, Value.Error>()
        
        onComplete(ec) { result in
            result.analysis(ifSuccess: { value in
                p.completeWith(f(value))
            }, ifFailure: { error in
                p.error(error)
            })
        }
        
        return p.future
    }
    
    /**

        Creates a new Future by filtering the value of the current Future with a predicate `p`

        - parameter ec: Execution context of `p`. By default is global queue
        - parameter p: Predicate function

        - returns: A new Future with value or nil

    */
    public func filter(ec: ExecutionContextType = Pure, p: Value.Value -> Bool) -> Future<Value.Value?, Value.Error> {
        return map(ec) { x in p(x) ? x : nil }
    }

    /**

        Zips with another future and returns a new Future which success result contains a tuple of two elements

        - parameter x: Another future

        - returns: Future with resuls of two futures
    */
    public func zip<F: FutureType where F.Value.Error == Value.Error>(x: F) -> Future<(Value.Value, F.Value.Value), Value.Error> {
        
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
    public func recover(ec: ExecutionContextType = Pure, r: Value.Error -> Value.Value) -> Future<Value.Value, Value.Error> {
        let p = Promise<Value.Value, Value.Error>()
        
        onComplete(ec) { result in
            result.analysis(ifSuccess: { value in
                p.success(value)
            }, ifFailure: { error in
                p.success(r(error))
            })
        }
        
        return p.future
    }

    /**

        Creates a new future that will handle fail results that this future might contain by assigning it a value of another future.

        - parameter ec: Execition context of `r` function. By default is global queue
        - parameter r: Recover function

        - returns: a new Future

    */
    public func recoverWith(ec: ExecutionContextType = Pure, r: Value.Error -> Self) -> Future<Value.Value, Value.Error> {
        let p = Promise<Value.Value, Value.Error>()
        onComplete(ec) { result in
            result.analysis(ifSuccess: { value in
                p.success(value)
            }, ifFailure: { error in
                p.completeWith(r(error))
            })
        }
        return p.future
    }

    /**

        Transforms Future<T, E> into Deferred<Result<T, E>>

        - returns: Deferred

    */
    public func toDeferred() -> Deferred<Result<Value.Value, Value.Error>> {
        let p = PurePromise<Result<Value.Value, Value.Error>>()
        onComplete(Pure) { result in
            p.complete(Result(result: result))
        }
        return p.deferred
    }

    /**

        Transforms Future<T, E> into Deferred<T> and handles error case with `r` function

        - parameter ec: Execution context of `r` function. By default is global queue
        - parameter r: Recover function

        - returns: Deferred with success value of `fx` or result of `r`

    */
    public func toDeferred(ec: ExecutionContextType = Pure, r: Value.Error -> Value.Value) -> Deferred<Value.Value> {
        let p = PurePromise<Value.Value>()
        onComplete(ec) { result in
            result.analysis(ifSuccess: { value in
                p.complete(value)
            }, ifFailure: { error in
                p.complete(r(error))
            })
        }
        return p.deferred
    }
}

// MARK: - Nested FutureType extension

extension FutureType where Value.Value: FutureType, Value.Value.Value.Error == Value.Error {
    
    /**

        Converts Future<Future<S, E>, E> into Future<S, E>

        - returns: flattened Future

    */
    public func flatten() -> Future<Value.Value.Value.Value, Value.Error> {
        let p = Promise<Value.Value.Value.Value, Value.Error>()
        
        onComplete(Pure) { result in
            result.analysis(ifSuccess: { value in
                p.completeWith(value)
            }, ifFailure: { error in
                p.error(error)
            })
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
    public func reduce<T>(ec: ExecutionContextType = Pure, initial: T, combine: (T, Generator.Element.Value.Value) -> T) -> Future<T, Generator.Element.Value.Error> {
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
    public func sequence() -> Future<[Generator.Element.Value.Value], Generator.Element.Value.Error> {
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
    public func traverse<F: FutureType>(ec: ExecutionContextType = Pure, f: Generator.Element -> F) -> Future<[F.Value.Value], F.Value.Error> {
        // TODO: Replace $0 + [$1] with the more efficien impl
        return map(f).reduce(ec, initial: []) { $0 + [$1] }
    }
    
}

// MARK: - Convenience extension

public extension FutureType {
    func onSuccess(ec: ExecutionContextType = SideEffects, _ c: Value.Value -> Void) -> Self {
        return onComplete(ec) { result in
            if let value = result.value {
                c(value)
            }
        }
    }
    
    func onError(ec: ExecutionContextType = SideEffects, _ c: Value.Error -> Void) -> Self {
        return onComplete(ec) { result in
            if let error = result.error {
                c(error)
            }
        }
    }
}