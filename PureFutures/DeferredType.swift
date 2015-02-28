//
//  DeferredType.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public protocol DeferredType {
    
    typealias Element
    
    init(_ x: Element)
    
    func onComplete(c: Element -> Void) -> Self
    
}
