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
        case sync
        case async
    }
    
    case main(ExecutionType)
    case global(ExecutionType)
}

// TODO: Lowercase it
internal let Pure = ExecutionContext.global(.async)
internal let SideEffects = ExecutionContext.main(.async)

private extension ExecutionContext.ExecutionType {
    func execute(_ queue: DispatchQueue, _ task: @escaping () -> Void) {
        switch self {
        case .sync:
            return queue.sync(execute: task)
        case .async:
            return queue.async(execute: task)
        }
    }
}

extension ExecutionContext: ExecutionContextType {
    public func execute(_ task: @escaping () -> Void) {
        switch self {
        case .main(let type):
            type.execute(DispatchQueue.main, task)
        case .global(let type):
            type.execute(DispatchQueue.global(), task)
        }
    }
}
