//
//  GCD+ExecutionContext.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/28/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

extension dispatch_queue_t: ExecutionContextType {
    public func execute(task: () -> Void) {
        dispatch_async(self, task)
    }
}
