//
//  ExecutionContext.swift
//  PureFutures
//
//  Created by Victor Shamanov on 4/17/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public enum ExecutionContext {
    
    public enum ExecutionType {
        case Sync
        case Async
    }
    
    case Main(ExecutionType)
    case Global(ExecutionType)
}

internal let Pure = ExecutionContext.Global(.Async)
internal let SideEffects = ExecutionContext.Main(.Async)

private extension ExecutionContext.ExecutionType {
    private func execute(queue: dispatch_queue_t, _ task: () -> Void) {
        switch self {
        case .Sync:
            return dispatch_sync(queue, task)
        case .Async:
            return dispatch_async(queue, task)
        }
    }
}

extension ExecutionContext: ExecutionContextType {
    public func execute(task: () -> Void) {
        switch self {
        case .Main(let type):
            type.execute(dispatch_get_main_queue(), task)
        case .Global(let type):
            type.execute(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), task)
        }
    }
}
