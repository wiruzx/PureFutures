//
//  DeferredTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

func map<T: DeferredType, U: DeferredType>(d: T, f: T.Element -> U.Element) -> U {
    return flatMap(d) { U.completed(f($0)) }
}

func flatMap<T: DeferredType, U: DeferredType>(d: T, f: T.Element -> U) -> U {
    let p = Promise<U.Element>()
    d.onComplete { p.completeWith(f($0) as Deferred<U.Element>) }
    return p.deferred as U
}
