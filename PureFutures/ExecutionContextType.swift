//
//  ExecutionContextType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/28/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation
    
public protocol ExecutionContextType {
    func execute(task: () -> Void)
}

// TODO: Move it to appropriate place
let defaultContext = NSOperationQueue.mainQueue()
