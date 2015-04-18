//
//  FutureType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public protocol FutureType: DeferredType {
    
    typealias SuccessType
    typealias ErrorType
    
    typealias Element = Result<SuccessType, ErrorType>
    
    func onComplete(ec: ExecutionContextType, _ c: Result<SuccessType, ErrorType> -> Void) -> Self
    
    func onSuccess(ec: ExecutionContextType, _ c: SuccessType -> Void) -> Self
    func onError(ec: ExecutionContextType, _ c: ErrorType -> Void) -> Self
    
}
