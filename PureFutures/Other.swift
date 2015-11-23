//
//  Other.swift
//  PureFutures
//
//  Created by Victor Shamanov on 3/1/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

internal func identity<T>(value: T) -> T {
    return value
}

internal func constant<T, A>(value: T) -> A -> T {
    return { _ in value }
}
