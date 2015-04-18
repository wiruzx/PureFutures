//
//  DeferredTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func andThen<D: DeferredType>(dx: D, f: D.Element -> Void)(_ ec: ExecutionContextType) -> Deferred<D.Element> {
    let p = PurePromise<D.Element>()
    dx.onComplete(ec) { value in
        f(value)
        p.complete(value)
    }
    return p.deferred
}

public func forced<D: DeferredType>(dx: D) -> D.Element {
    return forced(dx, NSTimeInterval.infinity)!
}

public func forced<D: DeferredType>(dx: D, interval: NSTimeInterval) -> D.Element? {
    return await(interval) { completion in
        dx.onComplete(ExecutionContext.DefaultPureOperationContext, completion)
        return
    }
}

public func map<D: DeferredType, T>(dx: D, f: D.Element -> T)(_ ec: ExecutionContextType) -> Deferred<T> {
    let p = PurePromise<T>()
    dx.onComplete(ec) { p.complete(f($0)) }
    return p.deferred
}

public func flatMap<D: DeferredType, D2: DeferredType>(dx: D, f: D.Element -> D2)(_ ec: ExecutionContextType) -> Deferred<D2.Element> {
    let p = PurePromise<D2.Element>()
    dx.onComplete(ec) { p.completeWith(f($0)) }
    return p.deferred
}

public func flatten<D: DeferredType, ID: DeferredType where D.Element == ID>(dx: D) -> Deferred<ID.Element> {
    let p = PurePromise<ID.Element>()
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    dx.onComplete(ec) { def in
        def.onComplete(ec) { p.complete($0) }
    }
    
    return p.deferred
}

public func filter<D: DeferredType>(dx: D, p: D.Element -> Bool)(_ ec: ExecutionContextType) -> Deferred<D.Element?> {
    return map(dx) { x in p(x) ? x : nil }(ec)
}

public func zip<DA: DeferredType, DB: DeferredType>(da: DA, db: DB) -> Deferred<(DA.Element, DB.Element)> {
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    return flatMap(da) { a in
        map(db) { b in
            (a, b)
        }(ec)
    }(ec)
}

public func reduce<S: SequenceType, T where S.Generator.Element: DeferredType>(dxs: S, initial: T, combine: (T, S.Generator.Element.Element) -> T)(_ ec: ExecutionContextType) -> Deferred<T> {
    return reduce(dxs, Deferred(initial)) { acc, defValue in
        flatMap(defValue) { value in
            map(acc) { combine($0, value) }(ec)
        }(ec)
    }
}

public func traverse<S: SequenceType, D: DeferredType>(xs: S, f: S.Generator.Element -> D)(_ ec: ExecutionContextType) -> Deferred<[D.Element]> {
    return reduce(map(xs, f), []) { $0 + [$1] }(ec)
}

public func sequence<S: SequenceType where S.Generator.Element: DeferredType>(dxs: S) -> Deferred<[S.Generator.Element.Element]> {
    return traverse(dxs, id)(ExecutionContext.DefaultPureOperationContext)
}

public func toFuture<D: DeferredType, T, E where D.Element == Result<T, E>>(dx: D) -> Future<T, E> {
    let p = Promise<T, E>()
    
    dx.onComplete(ExecutionContext.DefaultPureOperationContext) {
        p.complete($0)
    }
    
    return p.future
}
