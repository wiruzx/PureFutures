//
//  FutureType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import protocol Result.ResultType

public protocol FutureType: DeferredType {
    
    typealias Value: ResultType
    
    /**
        Register an callback which should be called when Future succeed

        Has a default implementation
    
        - parameter ec: execution context of callback
        - parameter c: callback
    
        - returns: Returns itself for chaining operations
    */
    func onSuccess(ec: ExecutionContextType, _ c: Value.Value -> Void) -> Self
    
    
    /**
        Register an callback which should be called when Future failed

        Has a default implementation
    
        - parameter ec: execution context of callback
        - parameter c: callback
    
        - returns: Returns itself for chaining operations
    */
    func onError(ec: ExecutionContextType, _ c: Value.Error -> Void) -> Self
    
}
