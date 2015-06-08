//
//  DeferredType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

public protocol DeferredType {
    
    typealias Element
    
    /**
        Register an callback which should be called when Deferred completed
    
        :param: ec execution context of callback
        :param: c callback
    
        :returns: Returns itself for chaining operations
    */
    func onComplete(ec: ExecutionContextType, _ c: Element -> Void) -> Self
    
}
