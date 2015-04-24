//
//  FutureType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

public protocol FutureType: DeferredType {
    
    typealias SuccessType
    typealias ErrorType
    
    typealias Element = Result<SuccessType, ErrorType>
    
    /**
        Register an callback which should be called when Future completed
    
        :param: ec execution context of callback
        :param: c callback
    
        :returns: Returns itself for chaining operations
    */
    func onComplete(ec: ExecutionContextType, _ c: Result<SuccessType, ErrorType> -> Void) -> Self
    
    /**
        Register an callback which should be called when Future succeed
    
        :param: ec execution context of callback
        :param: c callback
    
        :returns: Returns itself for chaining operations
    */
    func onSuccess(ec: ExecutionContextType, _ c: SuccessType -> Void) -> Self
    
    
    /**
        Register an callback which should be called when Future failed
    
        :param: ec execution context of callback
        :param: c callback
    
        :returns: Returns itself for chaining operations
    */
    func onError(ec: ExecutionContextType, _ c: ErrorType -> Void) -> Self
    
}
