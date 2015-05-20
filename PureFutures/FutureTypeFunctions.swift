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

    :param: fx Future
    :param: x recover value

    :returns: Deferred

*/
public func ??<F: FutureType>(fx: F, x: F.SuccessType) -> Deferred<F.SuccessType> {
    return toDeferred({ _ in x }, ExecutionContext.DefaultPureOperationContext)(fx)
}

/**

    Recovers future with another future.

    see: `recoverWith`

    :param: fx Future
    :param: x future which value will be used if `fx` fails

    :returns: a new Future

*/
public func ??<F: FutureType>(fx: F, x: F) -> Future<F.SuccessType, F.ErrorType> {
    return recoverWith({ _ in x }, ExecutionContext.DefaultPureOperationContext)(fx)
}

/**

    Applies the side-effecting function to the success result of this future,
    and returns a new future with the result of this future

    :param: f side-effecting function that will be applied to result of `fx`
    :param: ec execution context of `f` function. By default is main queue

    :param: fx Future

    :returns: a new Future

*/
public func andThen<F: FutureType>(f: (F.SuccessType -> Void), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let box):
            f(box.value)
            p.success(box.value)
        case .Error(let box):
            p.error(box.value)
        }
    }
    return p.future
}

/**

    Creates a new future by applying a function `f` to the success result of this future.

    :param: f Function that will be applied to success result of `fx`
    :param: ec Execution context of `f`. By default is global queue

    :param: Future

    :returns: a new Future

*/
public func map<F: FutureType, T>(f: (F.SuccessType -> T), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext) -> F -> Future<T, F.ErrorType> {
    return transform(f, id, ec)
}

/**

    Creates a new future by applying the 's' function to the successful result of this future, or the 'e' function to the failed result.

    :param: s Function that will be applied to success result of `fx`
    :param: e Function that will be applied to failed result of `fx`
    :param: ec Execution context of `s` and `e` functions. By default is global queue

    :param: fx Future

    :returns: a new Future
*/
public func transform<F: FutureType, S, E>(s: (F.SuccessType -> S), e: (F.ErrorType -> E), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Future<S, E> {
    let p = Promise<S, E>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let box):
            p.success(s(box.value))
        case .Error(let box):
            p.error(e(box.value))
        }
    }
    return p.future
}

/**

    Creates a new future by applying a function to the success result of this future, and returns the result of the function as the new future.

    :param: f Funcion that will be applied to success result of `fx`
    :param: ec Execution context of `f`. By default is global queue

    :param: fx Future

    :returns: a new Future

*/
public func flatMap<F: FutureType, F2: FutureType where F.ErrorType == F2.ErrorType>(f: (F.SuccessType -> F2), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Future<F2.SuccessType, F2.ErrorType> {
    let p = Promise<F2.SuccessType, F2.ErrorType>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let box):
            p.completeWith(f(box.value))
        case .Error(let box):
            p.complete(.error(box.value))
        }
    }
    return p.future
}

/**

    Converts Future<Future<S, E>, E> into Future<S, E>

    :param: fx Future

    :returns: flattened Future

*/
public func flatten<F: FutureType, IF: FutureType where F.SuccessType == IF, F.ErrorType == IF.ErrorType>(fx: F) -> Future<IF.SuccessType, IF.ErrorType> {
    let p = Promise<IF.SuccessType, IF.ErrorType>()
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    fx.onComplete(ec) { result in
        switch result {
        case .Success(let box):
            box.value.onComplete(ec) {
                p.complete($0)
            }
        case .Error(let box):
            p.error(box.value)
        }
    }
    
    return p.future
}

/**

    Creates a new Future by filtering the value of the current Future with a predicate `p`

    :param: p Predicate function
    :param: ec Execution context of `p`. By default is global queue

    :param: Future

    :returns: A new Future with value or nil

*/
public func filter<F: FutureType>(p: (F.SuccessType -> Bool), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext) -> F -> Future<F.SuccessType?, F.ErrorType> {
    return map({ x in p(x) ? x : nil }, ec)
}

/**

    Zips two future together and returns a new Future which success result contains a tuple of two elements

    :param: fa First future

    :param: fb Second future

    :returns: Future with resuls of two futures

*/
public func zip<F: FutureType, T: FutureType where F.ErrorType == T.ErrorType>(fa: F)(_ fb: T) -> Future<(F.SuccessType, T.SuccessType), F.ErrorType> {
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    return flatMap({ a in
        map({ b in
            (a, b)
        }, ec)(fb)
    }, ec)(fa)
}

/**

    Reduces the elements of sequence of futures using the specified reducing function `combine`

    :param: initial Initial value that will be passed as first argument in `combine` function
    :param: combine reducing function
    :param: ec Execution context of `combine`. By default is global queue

    :param: fxs Sequence of Futures

    :returns: Future which will contain result of reducing sequence of futures

*/
public func reduce<S: SequenceType, T where S.Generator.Element: FutureType>(initial: T, combine: ((T, S.Generator.Element.SuccessType) -> T), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fxs: S) -> Future<T, S.Generator.Element.ErrorType> {
    return reduce(fxs, Future(.success(initial))) { acc, futureValue in
        flatMap({ value in
            map({ combine($0, value) }, ec)(acc)
        }, ec)(futureValue)
    }
}

/**

    Transforms a sequence of values into Future of array of this values using the provided function `f`

    :param: f Function for transformation values into Future
    :param: ec Execution context of `f`. By default is global queue

    :param: xs Sequence of values

    :returns: a new Future

*/
public func traverse<S: SequenceType, F: FutureType>(f: (S.Generator.Element -> F), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ xs: S) -> Future<[F.SuccessType], F.ErrorType> {
    return reduce([], { $0 + [$1] }, ec)(map(xs, f))
}

/**

    Transforms a sequnce of Futures into Future of array of values:

    [Future<T, E>] -> Future<[T], E>

    :param: fxs Sequence of Futures

    :returns: Future with array of values

*/
public func sequence<S: SequenceType where S.Generator.Element: FutureType>(fxs: S) -> Future<[S.Generator.Element.SuccessType], S.Generator.Element.ErrorType> {
    return traverse(id, ExecutionContext.DefaultPureOperationContext)(fxs)
}

/**
    Creates a new future that will handle error value that this future might contain

    Returned future will never fail.
    
    See: `toDeferred`

    :param: r Recover function
    :param: ec Execution context of `r` function. By default is global queue

    :param: fx Future

    :returns: a new Future that will never fail

*/
public func recover<F: FutureType>(r: (F.ErrorType -> F.SuccessType), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let box):
            p.success(box.value)
        case .Error(let box):
            p.success(r(box.value))
        }
    }
    return p.future
}

/**

    Creates a new future that will handle fail results that this future might contain by assigning it a value of another future.

    :param: r Recover function
    :param: ec Execition context of `r` function. By default is global queue

    :param: fx Future

    :returns: a new Future

*/
public func recoverWith<F: FutureType>(r: (F.ErrorType -> F), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let box):
            p.success(box.value)
        case .Error(let box):
            p.completeWith(r(box.value))
        }
    }
    return p.future
}

/**

    Transforms Future<T, E> into Deferred<Result<T, E>>

    :param: fx Future

    :returns: Deferred

*/
public func toDeferred<F: FutureType>(fx: F) -> Deferred<Result<F.SuccessType, F.ErrorType>> {
    let p = PurePromise<Result<F.SuccessType, F.ErrorType>>()
    fx.onComplete(ExecutionContext.DefaultPureOperationContext) {
        p.complete($0)
    }
    return p.deferred
}

/**

    Transforms Future<T, E> into Deferred<T> and handles error case with `r` function

    :param: r Recover function
    :param: ec Execution context of `r` function. By default is global queue

    :param: fx Future

    :returns: Deferred with success value of `fx` or result of `r`

*/
public func toDeferred<F: FutureType>(r: (F.ErrorType -> F.SuccessType), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ fx: F) -> Deferred<F.SuccessType> {
    let p = PurePromise<F.SuccessType>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let box):
            p.complete(box.value)
        case .Error(let box):
            p.complete(r(box.value))
        }
    }
    return p.deferred
}
