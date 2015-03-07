//
//  PurePromiseTests.swift
//  PureFutures
//
//  Created by Victor Shamanov on 3/7/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import PureFutures
import XCTest

class PurePromiseTests: XCTestCase {
    
    var promise: PurePromise<Int>!

    override func setUp() {
        super.setUp()
        
        promise = PurePromise()
    }
    
    // MARK:- complete
    
    func testComplete() {
        
        let expectation = expectationWithDescription("Deferred is completed")
        
        promise.deferred.onComplete { result in
            XCTAssertEqual(result, 42)
            expectation.fulfill()
        }
        
        promise.complete(42)
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testCompleteOnBackgroundThread() {
        let expectation = expectationWithDescription("Deferred is completed")
        
        promise.deferred.onComplete(dispatch_get_global_queue(0, 0)) { result in
            XCTAssertEqual(result, 42)
            XCTAssertFalse(NSThread.isMainThread())
            expectation.fulfill()
        }
        
        promise.complete(42)
        
        waitForExpectationsWithTimeout(1, handler: nil)
        
    }
    
    // MARK:- completeWith
    
    func testCompleteWith() {
        
        let expectation = expectationWithDescription("Deferred is completed")
        
        let deferred = Deferred(42)
        
        promise.deferred.onComplete { result in
            XCTAssertEqual(result, 42)
            expectation.fulfill()
        }
        
        promise.completeWith(deferred)
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testCompleteWithOnBackgroundThread() {
        
        let expectation = expectationWithDescription("Deferred is completed")
        
        let deferred = Deferred(42)
        
        promise.deferred.onComplete(dispatch_get_global_queue(0, 0)) { result in
            XCTAssertEqual(result, 42)
            XCTAssertFalse(NSThread.isMainThread())
            expectation.fulfill()
        }
        
        promise.completeWith(deferred)
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
