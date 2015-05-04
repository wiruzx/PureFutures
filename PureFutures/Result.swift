//
//  Result.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/10/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

/**
    Used as result of computations which could 
    either complete with Success and Error cases
*/
public enum Result<T, E> {
    
    case Success(Box<T>)
    case Error(Box<E>)
    
    /// If result is Success returns value else `nil`
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
