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
public enum Result<T, E: ErrorType> {
    
    case Success(T)
    case Error(E)
    
    /// If result is Success returns value else `nil`
    public var value: T? {
        switch self {
        case .Success(let value):
            return value
        case .Error(_):
            return nil
        }
    }
}

public extension Result {
    
    func map<U>(f: T -> U) -> Result<U, E> {
        switch self {
        case .Success(let value):
            return .Success(f(value))
        case .Error(let error):
            return .Error(error)
        }
    }
    
    func flatMap<U>(f: T -> Result<U, E>) -> Result<U, E> {
        switch self {
        case .Success(let value):
            return f(value)
        case .Error(let error):
            return .Error(error)
        }
    }
    
}
