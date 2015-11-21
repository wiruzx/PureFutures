//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import typealias Foundation.NSTimeInterval

/**

    Transforms Future to Deferred using future's success value or `x` in case when future was completed with error

    - parameter fx: Future
    - parameter x: recover value

    - returns: Deferred

*/
public func ??<F: FutureType>(fx: F, x: F.Success) -> Deferred<F.Success> {
    return toDeferred({ _ in x }, ExecutionContext.DefaultPureOperationContext)(fx)
}

/**

    Recovers future with another future.

    see: `recoverWith`

    - parameter fx: Future
    - parameter x: future which value will be used if `fx` fails

    - returns: a new Future

*/
public func ??<F: FutureType>(fx: F, x: F) -> Future<F.Success, F.Error> {
    return recoverWith({ _ in x }, ExecutionContext.DefaultPureOperationContext)(fx)
}

/**

    Applies the side-effecting function to the success result of this future,
    and returns a new future with the result of this future

    - parameter f: side-effecting function that will be applied to result of `fx`
    - parameter ec: execution context of `f` function. By default is main queue

    - parameter fx: Future

    - returns: a new Future

*/
public func andThen<F: FutureType>(f: (F.Success -> Void), _ ec: ExecutionContextType = ExecutionContext.DefaultSideEffectsContext)(_ fx: F) -> Future<F.Success, F.Error> {
    let p = Promise<F.Success, F.Error>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let value):
            p.success(value)
            f(value)
        case .Error(let error):
            p.error(error)
        }
    }
    return p.future
}

/**

    Creates a new future by applying a function `f` to the success result of this future.

    - parameter f: Function that will be applied to success result of `fx`
    - parameter ec: Execution context of `f`. By default is global queue

    - parameter Future:

    - returns: a new Future

*/
public func map<F: FutureType, T>(f: (F.Success -> T), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext) -> F -> Future<T, F.Error> {
    return transform(f, id, ec)
}

/**

    Creates a new future by applying the 's' function to the successful result of this future, or the 'e' function to the failed result.

    - parameter s: Function that will be applied to success result of `fx`
    - parameter e: Function that will be applied to failed result of `fx`
    - parameter ec: Execution context of `s` and `e` functions. By default is global queue

    - parameter fx: Future

    - returns: a new Future
*/
public func transform<F: FutureType, S, E>(s: (F.Success -> S), _ e: (F.Error -> E), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Future<S, E> {
    let p = Promise<S, E>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let value):
            p.success(s(value))
        case .Error(let error):
            p.error(e(error))
        }
    }
    return p.future
}

/**

    Creates a new future by applying a function to the success result of this future, and returns the result of the function as the new future.

    - parameter f: Funcion that will be applied to success result of `fx`
    - parameter ec: Execution context of `f`. By default is global queue

    - parameter fx: Future

    - returns: a new Future

*/
public func flatMap<F: FutureType, F2: FutureType where F.Error == F2.Error>(f: (F.Success -> F2), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Future<F2.Success, F2.Error> {
    let p = Promise<F2.Success, F2.Error>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let value):
            p.completeWith(f(value))
        case .Error(let error):
            p.complete(.Error(error))
        }
    }
    return p.future
}

/**

    Converts Future<Future<S, E>, E> into Future<S, E>

    - parameter fx: Future

    - returns: flattened Future

*/
public func flatten<F: FutureType, IF: FutureType where F.Success == IF, F.Error == IF.Error>(fx: F) -> Future<IF.Success, IF.Error> {
    let p = Promise<IF.Success, IF.Error>()
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    fx.onComplete(ec) { result in
        switch result {
        case .Success(let value):
            value.onComplete(ec) {
                p.complete($0)
            }
        case .Error(let error):
            p.error(error)
        }
    }
    
    return p.future
}

/**

    Creates a new Future by filtering the value of the current Future with a predicate `p`

    - parameter p: Predicate function
    - parameter ec: Execution context of `p`. By default is global queue

    - parameter Future:

    - returns: A new Future with value or nil

*/
public func filter<F: FutureType>(p: (F.Success -> Bool), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext) -> F -> Future<F.Success?, F.Error> {
    return map({ x in p(x) ? x : nil }, ec)
}

/**

    Zips two future together and returns a new Future which success result contains a tuple of two elements

    - parameter fa: First future

    - parameter fb: Second future

    - returns: Future with resuls of two futures

*/
public func zip<F: FutureType, T: FutureType where F.Error == T.Error>(fa: F)(_ fb: T) -> Future<(F.Success, T.Success), F.Error> {
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    return flatMap({ a in
        map({ b in
            (a, b)
        }, ec)(fb)
    }, ec)(fa)
}

/**

    Reduces the elements of sequence of futures using the specified reducing function `combine`

    - parameter combine: reducing function
    - parameter initial: Initial value that will be passed as first argument in `combine` function
    - parameter ec: Execution context of `combine`. By default is global queue

    - parameter fxs: Sequence of Futures

    - returns: Future which will contain result of reducing sequence of futures

*/
public func reduce<S: SequenceType, T where S.Generator.Element: FutureType>(combine: ((T, S.Generator.Element.Success) -> T), _ initial: T, _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fxs: S) -> Future<T, S.Generator.Element.Error> {
    return fxs.reduce(.succeed(initial)) { acc, futureValue in
        flatMap({ value in
            map({ combine($0, value) }, ec)(acc)
        }, ec)(futureValue)
    }
}

/**

    Transforms a sequence of values into Future of array of this values using the provided function `f`

    - parameter f: Function for transformation values into Future
    - parameter ec: Execution context of `f`. By default is global queue

    - parameter xs: Sequence of values

    - returns: a new Future

*/
public func traverse<S: SequenceType, F: FutureType>(f: (S.Generator.Element -> F), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ xs: S) -> Future<[F.Success], F.Error> {
    return reduce({ $0 + [$1] }, [], ec)(xs.map(f))
}

/**

    Transforms a sequnce of Futures into Future of array of values:

    [Future<T, E>] -> Future<[T], E>

    - parameter fxs: Sequence of Futures

    - returns: Future with array of values

*/
public func sequence<S: SequenceType where S.Generator.Element: FutureType>(fxs: S) -> Future<[S.Generator.Element.Success], S.Generator.Element.Error> {
    return traverse(id, ExecutionContext.DefaultPureOperationContext)(fxs)
}

/**
    Creates a new future that will handle error value that this future might contain

    Returned future will never fail.
    
    See: `toDeferred`

    - parameter r: Recover function
    - parameter ec: Execution context of `r` function. By default is global queue

    - parameter fx: Future

    - returns: a new Future that will never fail

*/
public func recover<F: FutureType>(r: (F.Error -> F.Success), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Future<F.Success, F.Error> {
    let p = Promise<F.Success, F.Error>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let value):
            p.success(value)
        case .Error(let error):
            p.success(r(error))
        }
    }
    return p.future
}

/**

    Creates a new future that will handle fail results that this future might contain by assigning it a value of another future.

    - parameter r: Recover function
    - parameter ec: Execition context of `r` function. By default is global queue

    - parameter fx: Future

    - returns: a new Future

*/
public func recoverWith<F: FutureType>(r: (F.Error -> F), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Future<F.Success, F.Error> {
    let p = Promise<F.Success, F.Error>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let value):
            p.success(value)
        case .Error(let error):
            p.completeWith(r(error))
        }
    }
    return p.future
}

/**

    Transforms Future<T, E> into Deferred<Result<T, E>>

    - parameter fx: Future

    - returns: Deferred

*/
public func toDeferred<F: FutureType>(fx: F) -> Deferred<Result<F.Success, F.Error>> {
    let p = PurePromise<Result<F.Success, F.Error>>()
    fx.onComplete(ExecutionContext.DefaultPureOperationContext) {
        p.complete($0)
    }
    return p.deferred
}

/**

    Transforms Future<T, E> into Deferred<T> and handles error case with `r` function

    - parameter r: Recover function
    - parameter ec: Execution context of `r` function. By default is global queue

    - parameter fx: Future

    - returns: Deferred with success value of `fx` or result of `r`

*/
public func toDeferred<F: FutureType>(r: (F.Error -> F.Success), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Deferred<F.Success> {
    let p = PurePromise<F.Success>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let value):
            p.complete(value)
        case .Error(let error):
            p.complete(r(error))
        }
    }
    return p.deferred
}
