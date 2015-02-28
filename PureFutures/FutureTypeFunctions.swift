//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func map<F: FutureType, T>(fx: F, f: F.SuccessType -> T) -> Future<T, F.ErrorType> {
    return flatMap(fx) { Future(Result(f($0))) }
}

public func flatMap<F: FutureType, T>(fx: F, f: F.SuccessType -> Future<T, F.ErrorType>) -> Future<T, F.ErrorType> {
    let p = Promise<T, F.ErrorType>()
    fx.onComplete {
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
    return map(fx) { x in p(x) ? x : nil }
}

public func zip<F: FutureType, T: FutureType where F.ErrorType == T.ErrorType>(fa: F, fb: T) -> Future<(F.SuccessType, T.SuccessType), F.ErrorType> {
    return flatMap(fa) { a in
        map(fb) { b in
            (a, b)
        }
    }
}

public func reduce<F: FutureType, T>(fxs: [F], initial: T, combine: (T, F.SuccessType) -> T) -> Future<T, F.ErrorType> {
    return reduce(fxs, Future(Result(initial))) { acc, futureValue in
        flatMap(futureValue) { value in
            map(acc) { combine($0, value) }
        }
    }
}

public func traverse<T, F: FutureType>(xs: [T], f: T -> F) -> Future<[F.SuccessType], F.ErrorType> {
    return reduce(map(xs, f), []) { $0 + [$1] }
}

public func sequence<F: FutureType>(fxs: [F]) -> Future<[F.SuccessType], F.ErrorType> {
    return traverse(fxs) { $0 }
}

public func recover<F: FutureType>(fx: F, r: F.ErrorType -> F.SuccessType) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onError { p.success(r($0)) }
    return p.future
}

public func recoverWith<F: FutureType>(fx: F, r: F.ErrorType -> Future<F.SuccessType, F.ErrorType>) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onError { p.completeWith(r($0)) }
    return p.future
}
