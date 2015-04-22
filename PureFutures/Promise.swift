//
//  Promise.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public struct Promise<T, E> {
    
    // MARK:- Type declarations
    
    typealias Element = Result<T, E>
    
    // MARK:- Public properties
    
    public let future = Future<T, E>()
    
    public var isCompleted: Bool {
        return future.isCompleted
    }
    
    // MARK:- Initialization
    
    public init() {
    }
    
    // MARK:- PromiseType methods
    
    public func complete(value: Result<T, E>) {
        future.setValue(value)
    }
    
    public func completeWith<F: FutureType where F.SuccessType == T, F.ErrorType == E>(future: F) {
        future.onComplete(ExecutionContext.DefaultPureOperationContext) { self.complete($0) }
    }
    
    public func success(value: T) {
        complete(Result(value))
    }
    
    public func error(error: E) {
        complete(Result(error))
    }
    
    // MARK:- Other methods
    
    public func tryComplete(value: Result<T, E>) -> Bool {
        if isCompleted {
            return false
        } else {
            complete(value)
            return true
        }
    }
    
    public func trySuccess(value: T) -> Bool {
        return tryComplete(Result(value))
    }
    
    public func tryError(error: E) -> Bool {
        return tryComplete(Result(error))
    }
    
    public func tryCompleteWith<F: FutureType where F.SuccessType == T, F.ErrorType == E>(future: F) {
        future.onComplete(ExecutionContext.DefaultPureOperationContext) { self.tryComplete($0) }
    }
    
}
