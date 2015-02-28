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
