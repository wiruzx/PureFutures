//
//  FutureType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

public protocol FutureType: DeferredType {
    
    typealias Success
    typealias Error: ErrorType
    
    typealias Element = Result<Success, Error>
    
    /**
        Register an callback which should be called when Future completed
    
        - parameter ec: execution context of callback
        - parameter c: callback
    
        - returns: Returns itself for chaining operations
    */
    func onComplete(ec: ExecutionContextType, _ c: Result<Success, Error> -> Void) -> Self
    
    /**
        Register an callback which should be called when Future succeed
    
        - parameter ec: execution context of callback
        - parameter c: callback
    
        - returns: Returns itself for chaining operations
    */
    func onSuccess(ec: ExecutionContextType, _ c: Success -> Void) -> Self
    
    
    /**
        Register an callback which should be called when Future failed
    
        - parameter ec: execution context of callback
        - parameter c: callback
    
        - returns: Returns itself for chaining operations
    */
    func onError(ec: ExecutionContextType, _ c: Error -> Void) -> Self
    
}
