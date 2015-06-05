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
        Creates a new Deferred with given element
    
        :param: x an Element
    
        :returns: Returns new Deferred
    */
    static func create(x: Element) -> Self
    
    /**
        Register an callback which should be called when Deferred completed
    
        :param: ec execution context of callback
        :param: c callback
    
        :returns: Returns itself for chaining operations
    */
    func onComplete(ec: ExecutionContextType, _ c: Element -> Void) -> Self
    
}
