//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation



public func map<F: FutureType, T>(fx: F, f: F.SuccessType -> T) -> Future<T, F.ErrorType> {
    return map(defaultContext, fx, f)
}

public func map<F: FutureType, T>(ec: ExecutionContextType, fx: F, f: F.SuccessType -> T) -> Future<T, F.ErrorType> {
    return flatMap(ec, fx) { Future(Result(f($0))) }
}



public func flatMap<F: FutureType, T>(fx: F, f: F.SuccessType -> Future<T, F.ErrorType>) -> Future<T, F.ErrorType> {
    return flatMap(defaultContext, fx, f)
}

public func flatMap<F: FutureType, T>(ec: ExecutionContextType, fx: F, f: F.SuccessType -> Future<T, F.ErrorType>) -> Future<T, F.ErrorType> {
    let p = Promise<T, F.ErrorType>()
    fx.onComplete(ec) {
        switch $0 as Result<F.SuccessType, F.ErrorType> {
        case .Success(let box):
            p.completeWith(f(box.value))
        case .Error(let box):
            p.complete(Result(box.value))
        }
    }
    return p.future
}



public func filter<F: FutureType>(fx: F, p: F.SuccessType -> Bool) -> Future<F.SuccessType?, F.ErrorType> {
    return filter(defaultContext, fx, p)
}

public func filter<F: FutureType>(ec: ExecutionContextType, fx: F, p: F.SuccessType -> Bool) -> Future<F.SuccessType?, F.ErrorType> {
    return map(ec, fx) { x in p(x) ? x : nil }
}



public func zip<F: FutureType, T: FutureType where F.ErrorType == T.ErrorType>(fa: F, fb: T) -> Future<(F.SuccessType, T.SuccessType), F.ErrorType> {
    return zip(defaultContext, fa, fb)
}

public func zip<F: FutureType, T: FutureType where F.ErrorType == T.ErrorType>(ec: ExecutionContextType, fa: F, fb: T) -> Future<(F.SuccessType, T.SuccessType), F.ErrorType> {
    return flatMap(ec, fa) { a in
        map(ec, fb) { b in
            (a, b)
        }
    }
}



public func reduce<F: FutureType, T>(fxs: [F], initial: T, combine: (T, F.SuccessType) -> T) -> Future<T, F.ErrorType> {
    return reduce(defaultContext, fxs, initial, combine)
}

public func reduce<F: FutureType, T>(ec: ExecutionContextType, fxs: [F], initial: T, combine: (T, F.SuccessType) -> T) -> Future<T, F.ErrorType> {
    return Swift.reduce(fxs, Future(Result(initial))) { acc, futureValue in
        flatMap(ec, futureValue) { value in
            map(ec, acc) { combine($0, value) }
        }
    }
}



public func traverse<T, F: FutureType>(xs: [T], f: T -> F) -> Future<[F.SuccessType], F.ErrorType> {
    return traverse(defaultContext, xs, f)
}

public func traverse<T, F: FutureType>(ec: ExecutionContextType, xs: [T], f: T -> F) -> Future<[F.SuccessType], F.ErrorType> {
    return reduce(ec, map(xs, f), []) { $0 + [$1] }
}



public func sequence<F: FutureType>(fxs: [F]) -> Future<[F.SuccessType], F.ErrorType> {
    return sequence(defaultContext, fxs)
}

public func sequence<F: FutureType>(ec: ExecutionContextType, fxs: [F]) -> Future<[F.SuccessType], F.ErrorType> {
    return traverse(ec, fxs) { $0 }
}



public func recover<F: FutureType>(fx: F, r: F.ErrorType -> F.SuccessType) -> Future<F.SuccessType, F.ErrorType> {
    return recover(defaultContext, fx, r)
}

public func recover<F: FutureType>(ec: ExecutionContextType, fx: F, r: F.ErrorType -> F.SuccessType) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onError(ec) { p.success(r($0)) }
    return p.future
}



public func recoverWith<F: FutureType>(fx: F, r: F.ErrorType -> Future<F.SuccessType, F.ErrorType>) -> Future<F.SuccessType, F.ErrorType> {
    return recoverWith(defaultContext, fx, r)
}

public func recoverWith<F: FutureType>(ec: ExecutionContextType, fx: F, r: F.ErrorType -> Future<F.SuccessType, F.ErrorType>) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onError(ec) { p.completeWith(r($0)) }
    return p.future
}
