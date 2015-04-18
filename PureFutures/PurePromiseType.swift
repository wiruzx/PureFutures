//
//  PurePromiseType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public protocol PurePromiseType {
    
    typealias Element
    
    func complete(value: Element)
    func completeWith<D: DeferredType where D.Element == Element>(deferred: D)
    
}
