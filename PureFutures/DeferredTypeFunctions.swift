//
//  DeferredTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

let defaultContext = NSOperationQueue.mainQueue()


public func map<D: DeferredType, T>(dx: D, f: D.Element -> T) -> Deferred<T> {
    return map(defaultContext, dx, f)
}

public func map<D: DeferredType, T>(ec: ExecutionContextType, dx: D, f: D.Element -> T) -> Deferred<T> {
    return flatMap(ec, dx) { Deferred(f($0)) }
}



public func flatMap<D: DeferredType, T>(dx: D, f: D.Element -> Deferred<T>) -> Deferred<T> {
    return flatMap(defaultContext, dx, f)
}

public func flatMap<D: DeferredType, T>(ec: ExecutionContextType, dx: D, f: D.Element -> Deferred<T>) -> Deferred<T> {
    let p = PurePromise<T>()
    dx.onComplete(ec) { p.completeWith(f($0)) }
    return p.deferred
}



public func filter<D: DeferredType>(dx: D, p: D.Element -> Bool) -> Deferred<D.Element?> {
    return filter(defaultContext, dx, p)
}

public func filter<D: DeferredType>(ec: ExecutionContextType, dx: D, p: D.Element -> Bool) -> Deferred<D.Element?> {
    return map(ec, dx) { x in p(x) ? x : nil }
}



public func zip<D: DeferredType, T: DeferredType>(da: D, db: T) -> Deferred<(D.Element, T.Element)> {
    return zip(defaultContext, da, db)
}

public func zip<D: DeferredType, T: DeferredType>(ec: ExecutionContextType, da: D, db: T) -> Deferred<(D.Element, T.Element)> {
    return flatMap(ec, da) { a in
        map(ec, db) { b in
            (a, b)
        }
    }
}



public func reduce<D: DeferredType, T>(dx: [D], initial: T, combine: (T, D.Element) -> T) -> Deferred<T> {
    return reduce(defaultContext, dx, initial, combine)
}

public func reduce<D: DeferredType, T>(ec: ExecutionContextType, dx: [D], initial: T, combine: (T, D.Element) -> T) -> Deferred<T> {
    return reduce(dx, Deferred(initial)) { acc, defValue in
        flatMap(ec, defValue) { value in
            map(ec, acc) { combine($0, value) }
        }
    }
}



public func traverse<D, T: DeferredType>(xs: [D], f: D -> T) -> Deferred<[T.Element]> {
    return traverse(defaultContext, xs, f)
}

public func traverse<D, T: DeferredType>(ec: ExecutionContextType, xs: [D], f: D -> T) -> Deferred<[T.Element]> {
    return reduce(ec, map(xs, f), []) { $0 + [$1] }
}



public func sequence<D: DeferredType>(dxs: [D]) -> Deferred<[D.Element]> {
    return sequence(defaultContext, dxs)
}

public func sequence<D: DeferredType>(ec: ExecutionContextType, dxs: [D]) -> Deferred<[D.Element]> {
    return traverse(ec, dxs) { $0 }
}
