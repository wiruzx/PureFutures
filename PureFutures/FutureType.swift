//
//  FutureType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//
import enum Result.Result
import protocol Result.ResultType

public protocol FutureType: DeferredType {
    
    typealias Element: ResultType
    
    /**
        Register an callback which should be called when Future succeed
    
        - parameter ec: execution context of callback
        - parameter c: callback
    
        - returns: Returns itself for chaining operations
    */
    func onSuccess(ec: ExecutionContextType, _ c: Element.Value -> Void) -> Self
    
    
    /**
        Register an callback which should be called when Future failed
    
        - parameter ec: execution context of callback
        - parameter c: callback
    
        - returns: Returns itself for chaining operations
    */
    func onError(ec: ExecutionContextType, _ c: Element.Error -> Void) -> Self
    
}
