//
//  DeferredTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

@noreturn
func map<T: DeferredType, U: DeferredType>(d: T, f: T.Element -> U.Element) -> U {
}

@noreturn
func flatMap<T: DeferredType, U: DeferredType>(d: T, f: T.Element -> U) -> U {
}

@noreturn
func filter<T: DeferredType, U: DeferredType where U.Element == Optional<T.Element>>(d: T, p: T.Element -> Bool) -> U {
}
