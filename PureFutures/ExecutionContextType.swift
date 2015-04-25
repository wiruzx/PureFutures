//
//  ExecutionContextType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/28/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

public protocol ExecutionContextType {
    func execute(task: () -> Void)
}
