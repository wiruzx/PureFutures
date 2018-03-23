//
//  DeferredType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

public protocol DeferredType {
    
    associatedtype Value
    
    /**
        Register an callback which should be called when Deferred completed
    
        - parameter ec: execution context of callback
        - parameter c: callback
    
        - returns: Returns itself for chaining operations
    */
    
    @discardableResult
    func onComplete(_ c: @escaping (Value) -> Void) -> Self
    
}
