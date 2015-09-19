//
//  NSOperationQueue+ExecutionContext.swift
//  PureFutures
//
//  Created by Victor Shamanov on 3/1/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import class Foundation.NSOperationQueue

extension NSOperationQueue: ExecutionContextType {
    public func execute(task: () -> Void) {
        addOperationWithBlock(task)
    }
}
