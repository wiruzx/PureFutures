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
public func ??<F: FutureType>(fx: F, @autoclosure x: () -> F.SuccessType) -> Deferred<F.SuccessType> {
    let value = x()
    return toDeferred(fx) { _ in value }(ExecutionContext.DefaultPureOperationContext)
}

/**

    Recovers future with another future.

    see: `recoverWith`

    :param: fx Future
    :param: x future which value will be used if `fx` fails

    :returns: a new Future

*/
public func ??<F: FutureType>(fx: F, @autoclosure x: () -> F) -> Future<F.SuccessType, F.ErrorType> {
    let value = x()
    return recoverWith(fx) { _ in value }(ExecutionContext.DefaultPureOperationContext)
}


/**

    Applies the side-effecting function to the success result of this future,
    and returns a new future with the result of this future

    :param: fx Future
    :param: f side-effecting function that will be applied to result of `fx`
    :param: ec execution context of `f` function

    :returns: a new Future

*/
public func andThen<F: FutureType>(fx: F, f: F.SuccessType -> Void)(_ ec: ExecutionContextType) -> Future<F.SuccessType, F.ErrorType> {
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

    :param: fx Future
    :param: f Function that will be applied to success result of `fx`
    :param: ec Execution context of `f`

    :returns: a new Future

*/
public func map<F: FutureType, T>(fx: F, f: F.SuccessType -> T)(_ ec: ExecutionContextType) -> Future<T, F.ErrorType> {
    return transform(fx, f, id)(ec)
}

/**

    Creates a new future by applying the 's' function to the successful result of this future, or the 'e' function to the failed result.

    :param: fx Future
    :param: s Function that will be applied to success result of `fx`
    :param: e Function that will be applied to failed result of `fx`
    :param: ec Execution context of `s` and `e` functions

    :returns: a new Future
*/
public func transform<F: FutureType, S, E>(fx: F, s: F.SuccessType -> S, e: F.ErrorType -> E)(_ ec: ExecutionContextType) -> Future<S, E> {
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

    :param: fx Future
    :param: f Funcion that will be applied to success result of `fx`
    :param: ec Execution context of `f`

    :returns: a new Future

*/
public func flatMap<F: FutureType, F2: FutureType where F.ErrorType == F2.ErrorType>(fx: F, f: F.SuccessType -> F2)(_ ec: ExecutionContextType) -> Future<F2.SuccessType, F2.ErrorType> {
    let p = Promise<F2.SuccessType, F2.ErrorType>()
    fx.onComplete(ec) {
        switch $0 {
        case .Success(let box):
            p.completeWith(f(box.value))
        case .Error(let box):
            p.complete(Result(box.value))
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

    :param: fx Future
    :param: p Predicate function
    :param: ec Execution context of `p`

    :returns: A new Future with value or nil

*/
public func filter<F: FutureType>(fx: F, p: F.SuccessType -> Bool)(_ ec: ExecutionContextType) -> Future<F.SuccessType?, F.ErrorType> {
    return map(fx) { x in p(x) ? x : nil }(ec)
}

/**

    Zips two future together and returns a new Future which success result contains a tuple of two elements

    :param: fa First future
    :param: fb Second future

    :returns: Future with resuls of two futures

*/
public func zip<F: FutureType, T: FutureType where F.ErrorType == T.ErrorType>(fa: F, fb: T) -> Future<(F.SuccessType, T.SuccessType), F.ErrorType> {
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    return flatMap(fa) { a in
        map(fb) { b in
            (a, b)
        }(ec)
    }(ec)
}

/**

    Reduces the elements of sequence of futures using the specified reducing function `combine`

    :param: fxs Sequence of Futures
    :param: initial Initial value that will be passed as first argument in `combine` function
    :param: combine reducing function
    :param: ec Execution context of `combine`

    :returns: Future which will contain result of reducing sequence of futures

*/
public func reduce<S: SequenceType, T where S.Generator.Element: FutureType>(fxs: S, initial: T, combine: (T, S.Generator.Element.SuccessType) -> T)(_ ec: ExecutionContextType) -> Future<T, S.Generator.Element.ErrorType> {
    return reduce(fxs, Future(Result(initial))) { acc, futureValue in
        flatMap(futureValue) { value in
            map(acc) { combine($0, value)}(ec)
        }(ec)
    }
}

/**

    Transforms a sequence of values into Future of array of this values using the provided function `f`

    :param: xs Sequence of values
    :param: f Function for transformation values into Future
    :param: ec Execution context of `f`

    :returns: a new Future

*/
public func traverse<S: SequenceType, F: FutureType>(xs: S, f: S.Generator.Element -> F)(_ ec: ExecutionContextType) -> Future<[F.SuccessType], F.ErrorType> {
    return reduce(map(xs, f), []) { $0 + [$1] }(ec)
}

/**

    Transforms a sequnce of Futures into Future of array of values:

    [Future<T, E>] -> Future<[T], E>

    :param: fxs Sequence of Futures

    :returns: Future with array of values

*/
public func sequence<S: SequenceType where S.Generator.Element: FutureType>(fxs: S) -> Future<[S.Generator.Element.SuccessType], S.Generator.Element.ErrorType> {
    return traverse(fxs, id)(ExecutionContext.DefaultPureOperationContext)
}

/**
    Creates a new future that will handle error value that this future might contain

    Returned future will never fail.
    
    See: `toDeferred`

    :param: fx Future
    :param: r Recover function
    :param: ec Execution context of `r` function

    :returns: a new Future that will never fail

*/
public func recover<F: FutureType>(fx: F, r: F.ErrorType -> F.SuccessType)(_ ec: ExecutionContextType) -> Future<F.SuccessType, F.ErrorType> {
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

    :param: fx Future
    :param: r Recover function
    :param: ec Execition context of `r` function

    :returns: a new Future

*/
public func recoverWith<F: FutureType>(fx: F, r: F.ErrorType -> F)(_ ec: ExecutionContextType) -> Future<F.SuccessType, F.ErrorType> {
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

    :param: fx Future
    :param: r Recover function
    :param: ec Execution context of `r` function

    :returns: Deferred with success value of `fx` or result of `r`

*/
public func toDeferred<F: FutureType>(fx: F, r: F.ErrorType -> F.SuccessType)(_ ec: ExecutionContextType) -> Deferred<F.SuccessType> {
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
