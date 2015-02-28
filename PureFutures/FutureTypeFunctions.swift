//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func map<T: FutureType, U>(x: T, f: T.SuccessType -> U) -> Future<U, T.ErrorType> {
    return flatMap(x) { Future(Result(f($0))) }
}

public func flatMap<T: FutureType, U>(x: T, f: T.SuccessType -> Future<U, T.ErrorType>) -> Future<U, T.ErrorType> {
    let p = Promise<U, T.ErrorType>()
    
    x.onComplete {
        switch $0 as Result<T.SuccessType, T.ErrorType> {
        case .Success(let box):
            p.completeWith(f(box.value))
        case .Error(let box):
            p.complete(Result(box.value))
        }
    }
    
    return p.future
}

public func filter<T: FutureType>(x: T, p: T.SuccessType -> Bool) -> Future<T.SuccessType?, T.ErrorType> {
    return map(x) { x in p(x) ? x : nil }
}

public func zip<T: FutureType, U: FutureType where T.ErrorType == U.ErrorType>(a: T, b: U) -> Future<(T.SuccessType, U.SuccessType), T.ErrorType> {
    return flatMap(a) { a in
        map(b) { b in
            (a, b)
        }
    }
}

public func reduce<T: FutureType, U>(fs: [T], initial: U, combine: (U, T.SuccessType) -> U) -> Future<U, T.ErrorType> {
    return reduce(fs, Future(Result(initial))) { acc, futureValue in
        flatMap(futureValue) { value in
            map(acc) { combine($0, value) }
        }
    }
}

public func traverse<T, U: FutureType>(xs: [T], f: T -> U) -> Future<[U.SuccessType], U.ErrorType> {
    return reduce(map(xs, f), []) { $0 + [$1] }
}

public func sequence<T: FutureType>(fs: [T]) -> Future<[T.SuccessType], T.ErrorType> {
    return traverse(fs) { $0 }
}

public func recover<T: FutureType>(x: T, r: T.ErrorType -> T.SuccessType) -> Future<T.SuccessType, T.ErrorType> {
    let p = Promise<T.SuccessType, T.ErrorType>()
    x.onError { p.success(r($0)) }
    return p.future
}

public func recoverWith<T: FutureType>(x: T, r: T.ErrorType -> Future<T.SuccessType, T.ErrorType>) -> Future<T.SuccessType, T.ErrorType> {
    let p = Promise<T.SuccessType, T.ErrorType>()
    x.onError { p.completeWith(r($0)) }
    return p.future
}
