//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import typealias Foundation.NSTimeInterval

public func ??<F: FutureType>(fx: F, @autoclosure x: () -> F.SuccessType) -> Deferred<F.SuccessType> {
    let value = x()
    return toDeferred(fx) { _ in value }(ExecutionContext.DefaultPureOperationContext)
}

public func ??<F: FutureType>(fx: F, @autoclosure x: () -> F) -> Future<F.SuccessType, F.ErrorType> {
    let value = x()
    return recoverWith(fx) { _ in value }(ExecutionContext.DefaultPureOperationContext)
}

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

public func map<F: FutureType, T>(fx: F, f: F.SuccessType -> T)(_ ec: ExecutionContextType) -> Future<T, F.ErrorType> {
    return transform(fx, f, id)(ec)
}

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

public func filter<F: FutureType>(fx: F, p: F.SuccessType -> Bool)(_ ec: ExecutionContextType) -> Future<F.SuccessType?, F.ErrorType> {
    return map(fx) { x in p(x) ? x : nil }(ec)
}

public func zip<F: FutureType, T: FutureType where F.ErrorType == T.ErrorType>(fa: F, fb: T) -> Future<(F.SuccessType, T.SuccessType), F.ErrorType> {
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    return flatMap(fa) { a in
        map(fb) { b in
            (a, b)
        }(ec)
    }(ec)
}

public func reduce<S: SequenceType, T where S.Generator.Element: FutureType>(fxs: S, initial: T, combine: (T, S.Generator.Element.SuccessType) -> T)(_ ec: ExecutionContextType) -> Future<T, S.Generator.Element.ErrorType> {
    return reduce(fxs, Future(Result(initial))) { acc, futureValue in
        flatMap(futureValue) { value in
            map(acc) { combine($0, value)}(ec)
        }(ec)
    }
}

public func traverse<S: SequenceType, F: FutureType>(xs: S, f: S.Generator.Element -> F)(_ ec: ExecutionContextType) -> Future<[F.SuccessType], F.ErrorType> {
    return reduce(map(xs, f), []) { $0 + [$1] }(ec)
}

public func sequence<S: SequenceType where S.Generator.Element: FutureType>(fxs: S) -> Future<[S.Generator.Element.SuccessType], S.Generator.Element.ErrorType> {
    return traverse(fxs, id)(ExecutionContext.DefaultPureOperationContext)
}

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

public func toDeferred<F: FutureType>(fx: F) -> Deferred<Result<F.SuccessType, F.ErrorType>> {
    let p = PurePromise<Result<F.SuccessType, F.ErrorType>>()
    fx.onComplete(ExecutionContext.DefaultPureOperationContext) {
        p.complete($0)
    }
    return p.deferred
}

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
