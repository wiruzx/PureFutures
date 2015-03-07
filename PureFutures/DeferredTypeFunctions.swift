//
//  DeferredTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func forced<D: DeferredType>(dx: D) -> D.Element {
    return forced(dx, NSTimeInterval.infinity)!
}

public func forced<D: DeferredType>(dx: D, interval: NSTimeInterval) -> D.Element? {
    return await(interval) { completion in
        dx.onComplete(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), c: completion)
        return
    }
}

public func map<D: DeferredType, T>(dx: D, f: D.Element -> T) -> (ec: ExecutionContextType) -> Deferred<T> {
    return flatMap(dx) { Deferred(f($0)) }
}

public func flatMap<D: DeferredType, T>(dx: D, f: D.Element -> Deferred<T>)(ec: ExecutionContextType) -> Deferred<T> {
    let p = PurePromise<T>()
    dx.onComplete(ec) { p.completeWith(f($0)) }
    return p.deferred
}

public func filter<D: DeferredType>(dx: D, p: D.Element -> Bool) -> (ec: ExecutionContextType) -> Deferred<D.Element?> {
    return map(dx) { x in p(x) ? x : nil }
}

public func zip<D: DeferredType, T: DeferredType>(da: D, db: T)(ec: ExecutionContextType) -> Deferred<(D.Element, T.Element)> {
    return flatMap(da) { a in
        map(db) { b in
            (a, b)
        }(ec: ec)
    }(ec: ec)
}

public func reduce<D: DeferredType, T>(dx: [D], initial: T, combine: (T, D.Element) -> T)(ec: ExecutionContextType) -> Deferred<T> {
    return reduce(dx, Deferred(initial)) { acc, defValue in
        flatMap(defValue) { value in
            map(acc) { combine($0, value) }(ec: ec)
        }(ec: ec)
    }
}

public func traverse<D, T: DeferredType>(xs: [D], f: D -> T) -> (ec: ExecutionContextType) -> Deferred<[T.Element]> {
    return reduce(map(xs, f), []) { $0 + [$1] }
}

public func sequence<D: DeferredType>(dxs: [D]) -> (ec: ExecutionContextType) -> Deferred<[D.Element]> {
    return traverse(dxs, id)
}
