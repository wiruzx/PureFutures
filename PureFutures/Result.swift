//
//  Result.swift
//  PureFutures
//
//  Created by Victor Shamanov on 23/03/2018.
//  Copyright © 2018 Victor Shamanov. All rights reserved.
//

public enum Result<T> {
    case success(T)
    case failure(Error)
}
