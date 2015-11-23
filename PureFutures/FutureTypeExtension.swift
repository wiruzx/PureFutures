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
public func ??<F: FutureType>(fx: F, x: F.Element.Value) -> Deferred<F.Element.Value> {
    return fx.toDeferred(r: constant(x))
}

/**

    Recovers future with another future.

    see: `recoverWith`

    - parameter fx: Future
    - parameter x: future which value will be used if `fx` fails

    - returns: a new Future

*/
public func ??<F: FutureType>(fx: F, x: F) -> Future<F.Element.Value, F.Element.Error> {
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
    public func andThen(ec: ExecutionContextType = SideEffects, f: Element.Value -> Void) -> Future<Element.Value, Element.Error> {
        let p = Promise<Element.Value, Element.Error>()
        
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
    public func map<T>(ec: ExecutionContextType = Pure, f: Element.Value -> T) -> Future<T, Element.Error> {
        return transform(ec, s: f, e: identity)
    }
    
    /**

        Creates a new future by applying the 's' function to the successful result of this future, or the 'e' function to the failed result.

        - parameter ec: Execution context of `s` and `e` functions. By default is global queue
        - parameter s: Function that will be applied to success result of `fx`
        - parameter e: Function that will be applied to failed result of `fx`

        - returns: a new Future
    */
    public func transform<S, E: ErrorType>(ec: ExecutionContextType = Pure, s: Element.Value -> S, e: Element.Error -> E) -> Future<S, E> {
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
    public func flatMap<F: FutureType where F.Element.Error == Element.Error>(ec: ExecutionContextType = Pure, f: Element.Value -> F) -> Future<F.Element.Value, Element.Error> {
        let p = Promise<F.Element.Value, Element.Error>()
        
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
    public func filter(ec: ExecutionContextType = Pure, p: Element.Value -> Bool) -> Future<Element.Value?, Element.Error> {
        return map(ec) { x in p(x) ? x : nil }
    }

    /**

        Zips with another future and returns a new Future which success result contains a tuple of two elements

        - parameter x: Another future

        - returns: Future with resuls of two futures
    */
    public func zip<F: FutureType where F.Element.Error == Element.Error>(x: F) -> Future<(Element.Value, F.Element.Value), Element.Error> {
        
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
    public func recover(ec: ExecutionContextType = Pure, r: Element.Error -> Element.Value) -> Future<Element.Value, Element.Error> {
        let p = Promise<Element.Value, Element.Error>()
        
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
    public func recoverWith(ec: ExecutionContextType = Pure, r: Element.Error -> Self) -> Future<Element.Value, Element.Error> {
        let p = Promise<Element.Value, Element.Error>()
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
    public func toDeferred() -> Deferred<Result<Element.Value, Element.Error>> {
        let p = PurePromise<Result<Element.Value, Element.Error>>()
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
    public func toDeferred(ec: ExecutionContextType = Pure, r: Element.Error -> Element.Value) -> Deferred<Element.Value> {
        let p = PurePromise<Element.Value>()
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

extension FutureType where Element.Value: FutureType, Element.Value.Element.Error == Element.Error {
    
    /**

        Converts Future<Future<S, E>, E> into Future<S, E>

        - returns: flattened Future

    */
    public func flatten() -> Future<Element.Value.Element.Value, Element.Error> {
        let p = Promise<Element.Value.Element.Value, Element.Error>()
        
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
    public func reduce<T>(ec: ExecutionContextType = Pure, initial: T, combine: (T, Generator.Element.Element.Value) -> T) -> Future<T, Generator.Element.Element.Error> {
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
    public func sequence() -> Future<[Generator.Element.Element.Value], Generator.Element.Element.Error> {
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
    public func traverse<F: FutureType>(ec: ExecutionContextType = Pure, f: Generator.Element -> F) -> Future<[F.Element.Value], F.Element.Error> {
        // TODO: Replace $0 + [$1] with the more efficien impl
        return map(f).reduce(ec, initial: []) { $0 + [$1] }
    }
    
}
