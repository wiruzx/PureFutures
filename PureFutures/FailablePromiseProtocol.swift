//
//  FailablePromiseProtocol.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

protocol FailablePromiseProtocol: PromiseProtocol {
    
    typealias DeferredType : FutureProtocol
    
    typealias SuccessType = DeferredType.SuccessType
    typealias FailureType = DeferredType.FailureType

    func success(value: SuccessType)
    func failure(error: FailureType)
    
}
