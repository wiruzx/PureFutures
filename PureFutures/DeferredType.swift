//
//  DeferredType.swift
//  PureFutures
//
//  Created by Виктор Шаманов on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public protocol DeferredType {
    
    typealias Element
    
    class func completed(value: Element) -> Self
    
    func onComplete(c: Element -> Void) -> Self
    
}
