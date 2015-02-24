//
//  PromiseProtocol.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

protocol PromiseProtocol {
    
    typealias DeferredType : DeferredProtocol
    typealias Element = DeferredType.Element
    
    func complete(value: Element)
    func completeWith(deferred: DeferredType)
}
