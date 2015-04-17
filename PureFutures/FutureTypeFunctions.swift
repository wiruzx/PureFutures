//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func andThen<F: FutureType>(fx: F, f: F.SuccessType -> Void)(ec: ExecutionContextType) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onComplete(ec) {
        switch $0 as! Result<F.SuccessType, F.ErrorType> {
        case .Success(let box):
            f(box.value)
            p.success(box.value)
        case .Error(let box):
            p.error(box.value)
        }
    }
    return p.future
}

public func map<F: FutureType, T>(fx: F, f: F.SuccessType -> T)(ec: ExecutionContextType) -> Future<T, F.ErrorType> {
    return transform(fx, f, id)(ec: ec)
}

public func transform<F: FutureType, S, E>(fx: F, s: F.SuccessType -> S, e: F.ErrorType -> E)(ec: ExecutionContextType) -> Future<S, E> {
    let p = Promise<S, E>()
    fx.onComplete(ec) {
        switch $0 as! Result<F.SuccessType, F.ErrorType> {
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
        switch $0 as! Result<F.SuccessType, F.ErrorType> {
        case .Success(let box):
            p.completeWith(f(box.value))
        case .Error(let box):
            p.complete(Result(box.value))
        }
    }
    return p.future
}

public func flatten<F: FutureType, IF: FutureType where F.SuccessType == IF, F.ErrorType == IF.ErrorType>(fx: F)(ec: ExecutionContextType) -> Future<IF.SuccessType, IF.ErrorType> {
    let p = Promise<IF.SuccessType, IF.ErrorType>()
    
    fx.onComplete(ec) { result in
        switch result as! Result<IF, F.ErrorType> {
        case .Success(let box):
            box.value.onComplete(ec) {
                p.complete($0 as! Result<IF.SuccessType, IF.ErrorType>)
            }
        case .Error(let box):
            p.error(box.value)
        }
    }
    
    return p.future
}

public func filter<F: FutureType>(fx: F, p: F.SuccessType -> Bool)(ec: ExecutionContextType) -> Future<F.SuccessType?, F.ErrorType> {
    return map(fx) { x in p(x) ? x : nil }(ec: ec)
}

public func zip<F: FutureType, T: FutureType where F.ErrorType == T.ErrorType>(fa: F, fb: T)(ec: ExecutionContextType) -> Future<(F.SuccessType, T.SuccessType), F.ErrorType> {
    return flatMap(fa) { a in
        map(fb) { b in
            (a, b)
        }(ec: ec)
    }(ec: ec)
}

public func reduce<S: SequenceType, T where S.Generator.Element: FutureType>(fxs: S, initial: T, combine: (T, S.Generator.Element.SuccessType) -> T)(ec: ExecutionContextType) -> Future<T, S.Generator.Element.ErrorType> {
    return reduce(fxs, Future(Result(initial))) { acc, futureValue in
        flatMap(futureValue) { value in
            map(acc) { combine($0, value)}(ec: ec)
        }(ec: ec)
    }
}

public func traverse<S: SequenceType, F: FutureType>(xs: S, f: S.Generator.Element -> F)(ec: ExecutionContextType) -> Future<[F.SuccessType], F.ErrorType> {
    return reduce(map(xs, f), []) { $0 + [$1] }(ec: ec)
}

public func sequence<S: SequenceType where S.Generator.Element: FutureType>(fxs: S)(ec: ExecutionContextType) -> Future<[S.Generator.Element.SuccessType], S.Generator.Element.ErrorType> {
    return traverse(fxs, id)(ec: ec)
}

public func recover<F: FutureType>(fx: F, r: F.ErrorType -> F.SuccessType)(ec: ExecutionContextType) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onComplete(ec) {
        switch $0 as! Result<F.SuccessType, F.ErrorType> {
        case .Success(let box):
            p.success(box.value)
        case .Error(let box):
            p.success(r(box.value))
        }
    }
    return p.future
}

public func recoverWith<F: FutureType>(fx: F, r: F.ErrorType -> Future<F.SuccessType, F.ErrorType>)(ec: ExecutionContextType) -> Future<F.SuccessType, F.ErrorType> {
    let p = Promise<F.SuccessType, F.ErrorType>()
    fx.onComplete(ec) {
        switch $0 as! Result<F.SuccessType, F.ErrorType> {
        case .Success(let box):
            p.success(box.value)
        case .Error(let box):
            p.completeWith(r(box.value))
        }
    }
    return p.future
}

public func toDeferred<F: FutureType>(fx: F)(ec: ExecutionContextType) -> Deferred<Result<F.SuccessType, F.ErrorType>> {
    let p = PurePromise<Result<F.SuccessType, F.ErrorType>>()
    fx.onComplete(ec) { p.complete($0 as! Result<F.SuccessType, F.ErrorType>) }
    return p.deferred
}

public func toDeferred<F: FutureType>(fx: F, r: F.ErrorType -> F.SuccessType)(ec: ExecutionContextType) -> Deferred<F.SuccessType> {
    let p = PurePromise<F.SuccessType>()
    fx.onComplete(ec) {
        switch $0 as! Result<F.SuccessType, F.ErrorType> {
        case .Success(let box):
            p.complete(box.value)
        case .Error(let box):
            p.complete(r(box.value))
        }
    }
    return p.deferred
}
