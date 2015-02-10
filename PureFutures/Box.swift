//
//  Box.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/10/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public struct Box<T> {
    
    private let storage: [T]
    
    public var value: T {
        return storage.first!
    }
    
    public init(_ value: T) {
        storage = [value]
    }
}

public extension Box {
    
    public func map<U>(f: T -> U) -> Box<U> {
        return Box<U>(f(value))
    }
    
    public func flatMap<U>(f: T -> Box<U>) -> Box<U> {
        return f(value)
    }
    
}
