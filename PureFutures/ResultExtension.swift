//
//  ResultExtension.swift
//  PureFutures
//
//  Created by Victor Shamanov on 23.11.15.
//  Copyright © 2015 Victor Shamanov. All rights reserved.
//

import enum Result.Result
import protocol Result.ResultType

extension Result {
    init<R: ResultType>(result: R) where R.Value == Value, R.Error == Error {
        
        if let result = result as? Result {
            self = result
            return
        }
        
        var res: Result<Value, Error>? {
            didSet {
                if oldValue != nil {
                    fatalError("Setting result twice")
                }
            }
        }
        
        result.analysis(ifSuccess: {
            res = .Success($0)
        }, ifFailure: {
            res = .Failure($0)
        })
        
        guard let result = res else {
            fatalError("Non of analisys closures was called")
        }
        
        self = result
    }
}
