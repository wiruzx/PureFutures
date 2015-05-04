//
//  Box.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/10/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

/// Workaround for unimplemented IR generation for non-fixed multi-payload enum layout
public struct Box<T> {
    
    private let storage: [T]
    
    public var value: T {
        return storage.first!
    }
    
    public init(_ value: T) {
        storage = [value]
    }
}
