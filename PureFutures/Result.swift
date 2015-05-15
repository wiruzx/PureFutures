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
}

public extension Result {
    
    static func success(value: T) -> Result {
        return Result.Success(Box(value))
    }
    
    static func error(error: E) -> Result {
        return Result.Error(Box(error))
    }

}
