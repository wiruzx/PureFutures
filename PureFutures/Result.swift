//
//  Result.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/10/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public enum Result<T, E> {
    case Success(Box<T>)
    case Error(Box<E>)
    
    public var value: T? {
        switch self {
        case .Success(let boxed):
            return boxed.value
        default:
            return nil
        }
    }
    
    public init(_ value: T) {
        self = .Success(Box(value))
    }
    
    public init(_ error: E) {
        self = .Error(Box(error))
    }
}

public extension Result {
    
    public func map<U>(f: T -> U) -> Result<U, E> {
        switch self {
        case .Success(let boxed):
            return .Success(boxed.map(f))
        case .Error(let boxed):
            return .Error(Box(boxed.value))
        }
    }
    
    public func flatMap<U>(f: T -> Result<U, E>) -> Result<U, E> {
        switch self {
        case .Success(let boxed):
            return f(boxed.value)
        case .Error(let boxed):
            return .Error(Box(boxed.value))
        }
    }
    
    public func filter(p: T -> Bool) -> Result<T?, E> {
        return map { value in p(value) ? value : nil }
    }
    
}
