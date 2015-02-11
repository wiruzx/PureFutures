//
//  FutureProtocol.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public protocol FutureProtocol: DeferredProtocol {
    
    typealias SuccessType
    typealias FailureType
    
    typealias Element = Result<SuccessType, FailureType>
    
    func onSuccess(SuccessType -> Void) -> Self
    func onFailure(FailureType -> Void) -> Self
    
}
