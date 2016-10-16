//
//  ResultExtension.swift
//  PureFutures
//
//  Created by Victor Shamanov on 23.11.15.
//  Copyright © 2015 Victor Shamanov. All rights reserved.
//

import enum Result.Result
import protocol Result.ResultProtocol

extension Result {
    init<R: ResultProtocol>(result: R) where R.Value == Value, R.Error == Error {
        if let result = result as? Result {
            self = result
            return
        }
        
        var res: Result<Value, Error>?
        
        result.analysis(ifSuccess: {
            guard res == nil else { fatalError("Setting result twice") }
            res = .success($0)
        }, ifFailure: {
            guard res == nil else { fatalError("Settings result twice") }
            res = .failure($0)
        })
        
        guard let result = res else {
            fatalError("Non of analisys closures was called")
        }
        
        self = result
    }
}
