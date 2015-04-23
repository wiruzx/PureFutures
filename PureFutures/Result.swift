//
//  Result.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/10/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

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
