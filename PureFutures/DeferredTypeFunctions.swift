//
//  DeferredTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func map<D: DeferredType, T>(dx: D, f: D.Element -> T) -> Deferred<T> {
    return flatMap(dx) { Deferred(f($0)) }
}

public func flatMap<D: DeferredType, T>(dx: D, f: D.Element -> Deferred<T>) -> Deferred<T> {
    let p = PurePromise<T>()
    dx.onComplete { p.completeWith(f($0)) }
    return p.deferred
}

public func filter<D: DeferredType>(dx: D, p: D.Element -> Bool) -> Deferred<D.Element?> {
    return map(dx) { x in p(x) ? x : nil }
}

public func zip<D: DeferredType, T: DeferredType>(da: D, db: T) -> Deferred<(D.Element, T.Element)> {
    return flatMap(da) { a in
        map(db) { b in
            (a, b)
        }
    }
}

public func reduce<D: DeferredType, T>(dx: [D], initial: T, combine: (T, D.Element) -> T) -> Deferred<T> {
    return reduce(dx, Deferred(initial)) { acc, defValue in
        flatMap(defValue) { value in
            map(acc) { combine($0, value) }
        }
    }
}

public func traverse<D, T: DeferredType>(xs: [D], f: D -> T) -> Deferred<[T.Element]> {
    return reduce(map(xs, f), []) { $0 + [$1] }
}

public func sequence<D: DeferredType>(dxs: [D]) -> Deferred<[D.Element]> {
    return traverse(dxs) { $0 }
}

