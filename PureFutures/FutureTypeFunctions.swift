//
//  FutureTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

@noreturn
func map<T: FutureType, U: FutureType>(x: T, f: T.SuccessType -> U.SuccessType) -> U {
}

@noreturn
func flatMap<T: FutureType, U: FutureType>(x: T, f: T.SuccessType -> U) -> U {
}

@noreturn
func filter<T: FutureType, U: FutureType where U.SuccessType == Optional<T.SuccessType>>(x: T, p: T.SuccessType -> Bool) -> U {
}
