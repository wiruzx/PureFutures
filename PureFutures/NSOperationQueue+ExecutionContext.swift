//
//  NSOperationQueue+ExecutionContext.swift
//  PureFutures
//
//  Created by Victor Shamanov on 3/1/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import class Foundation.NSOperationQueue

extension OperationQueue: ExecutionContextType {
    public func execute(_ task: () -> Void) {
        addOperation(task)
    }
}
