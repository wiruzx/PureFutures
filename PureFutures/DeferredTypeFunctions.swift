//
//  DeferredTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func map<T: DeferredType, U>(d: T, f: T.Element -> U) -> Deferred<U> {
    return flatMap(d) { Deferred(f($0)) }
}

public func flatMap<T: DeferredType, U>(d: T, f: T.Element -> Deferred<U>) -> Deferred<U> {
    let p = PurePromise<U>()
    d.onComplete { p.completeWith(f($0)) }
    return p.deferred
}

public func filter<T: DeferredType>(d: T, p: T.Element -> Bool) -> Deferred<T.Element?> {
    return map(d) { x in p(x) ? x : nil }
}

public func zip<T: DeferredType, U: DeferredType>(a: T, b: U) -> Deferred<(T.Element, U.Element)> {
    return flatMap(a) { a in
        map(b) { b in
            (a, b)
        }
    }
}
