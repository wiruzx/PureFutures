//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

func map<T: FutureType, U: FutureType where T.FailureType == U.FailureType>(x: T, f: T.SuccessType -> U.SuccessType) -> U {
    return flatMap(x) { (value: T.SuccessType) in
        let result: Result<U.SuccessType, U.FailureType> = .Success(Box(f(value)))
        return U.completed(result as U.Element)
    }
}

func flatMap<T: FutureType, U: FutureType where T.FailureType == U.FailureType>(x: T, f: T.SuccessType -> U) -> U {
    let p = FailablePromise<U.SuccessType, U.FailureType>()
    
    x.onComplete {
        switch $0 as Result<T.SuccessType, T.FailureType> {
        case .Success(let box):
            p.completeWith(f(box.value) as Future<U.SuccessType, U.FailureType>)
        case .Error(let box):
            p.complete(.Error(Box(box.value as U.FailureType)))
        }
    }
    
    return p.future as U
}
