//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func map<F: FutureType, T>(fx: F, f: F.SuccessType -> T) -> (ec: ExecutionContextType) -> Future<T, F.ErrorType> {
    return transform(fx, f, { $0 })
}

public func transform<F: FutureType, T, E>(fx: F, s: F.SuccessType -> T, e: F.ErrorType -> E)(ec: ExecutionContextType) -> Future<T, E> {
    let p = Promise<T, E>()
    fx.onComplete(ec) {
        switch $0 as Result<F.SuccessType, F.ErrorType> {
        case .Success(let box):
            p.success(s(box.value))
        case .Error(let box):
            p.error(e(box.value))
        }
    }
    return p.future
}

public func flatMap<F: FutureType, T>(fx: F, f: F.SuccessType -> Future<T, F.ErrorType>)(ec: ExecutionContextType) -> Future<T, F.ErrorType> {
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

public func filter<F: FutureType>(fx: F, p: F.SuccessType -> Bool) -> (ec: ExecutionContextType) -> Future<F.SuccessType?, F.ErrorType> {
    return map(fx) { x in p(x) ? x : nil }
}

public func zip<F: FutureType, T: FutureType where F.ErrorType == T.ErrorType>(fa: F, fb: T)(ec: ExecutionContextType) -> Future<(F.SuccessType, T.SuccessType), F.ErrorType> {
    return flatMap(fa) { a in
        map(fb) { b in
            (a, b)
        }(ec: ec)
    }(ec: ec)
}

public func reduce<F: FutureType, T>(fxs: [F], initial: T, combine: (T, F.SuccessType) -> T)(ec: ExecutionContextType) -> Future<T, F.ErrorType> {
    return reduce(fxs, Future(Result(initial))) { acc, futureValue in
        flatMap(futureValue) { value in
            map(acc) { combine($0, value) }(ec: ec)
        }(ec: ec)
    }
}

public func traverse<T, F: FutureType>(xs: [T], f: T -> F) -> (ec: ExecutionContextType) -> Future<[F.SuccessType], F.ErrorType> {
    return reduce(map(xs, f), []) { $0 + [$1] }
}

public func sequence<F: FutureType>(fxs: [F]) -> (ec: ExecutionContextType) -> Future<[F.SuccessType], F.ErrorType> {
    return traverse(fxs) { $0 }
}

public func recover<F: FutureType>(fx: F, r: F.ErrorType -> F.SuccessType)(ec: ExecutionContextType) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onError(ec) { p.success(r($0)) }
    return p.future
}

public func recoverWith<F: FutureType>(fx: F, r: F.ErrorType -> Future<F.SuccessType, F.ErrorType>)(ec: ExecutionContextType) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onError(ec) { p.completeWith(r($0)) }
    return p.future
}
