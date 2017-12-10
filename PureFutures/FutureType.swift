//
//  FutureType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import protocol Result.ResultProtocol

public protocol FutureType: DeferredType where Value: ResultProtocol {
    
}
