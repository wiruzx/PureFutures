//
//  Operators.swift
//  PureFutures
//
//  Created by Victor Shamanov on 5/21/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

infix operator |> {
    associativity left
}

public func |> <T, U>(lhs: T, rhs: T -> U) -> U {
    return rhs(lhs)
}
