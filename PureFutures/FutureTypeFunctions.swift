//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public func map<T: FutureType, U: FutureType where T.ErrorType == U.ErrorType>(x: T, f: T.SuccessType -> U.SuccessType) -> U {
    return flatMap(x) { (value: T.SuccessType) in
        let result: Result<U.SuccessType, U.ErrorType> = Result(f(value))
        return U.completed(result as U.Element)
    }
}

public func flatMap<T: FutureType, U: FutureType where T.ErrorType == U.ErrorType>(x: T, f: T.SuccessType -> U) -> U {
    let p = Promise<U.SuccessType, U.ErrorType>()
    
    x.onComplete {
        switch $0 as Result<T.SuccessType, T.ErrorType> {
        case .Success(let box):
            p.completeWith(f(box.value) as Future<U.SuccessType, U.ErrorType>)
        case .Error(let box):
            p.complete(Result(box.value as U.ErrorType))
        }
    }
    
    return p.future as U
}
