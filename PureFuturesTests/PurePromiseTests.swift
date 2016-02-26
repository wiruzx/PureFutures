//
//  PurePromiseTests.swift
//  PureFutures
//
//  Created by Victor Shamanov on 3/7/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import XCTest

import PureFutures

class PurePromiseTests: XCTestCase {
    
    var promise: PurePromise<Int>!

    override func setUp() {
        super.setUp()
        
        promise = PurePromise()
    }
    
    // MARK:- isCompleted
    
    func testIsCompleted() {
        promise.complete(42)
        XCTAssertTrue(promise.isCompleted)
    }
    
    func testIsCompletedFalse() {
        XCTAssertFalse(promise.isCompleted)
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
        
        promise.deferred.onComplete { result in
            XCTAssertEqual(result, 42)
            expectation.fulfill()
        }
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            self.promise.complete(42)
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
        
    }
    
    // MARK:- completeWith
    
    func testCompleteWith() {
        
        let expectation = expectationWithDescription("Deferred is completed")
        
        let deferred = Deferred.completed(42)
        
        promise.deferred.onComplete { result in
            XCTAssertEqual(result, 42)
            expectation.fulfill()
        }
        
        promise.completeWith(deferred)
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testCompleteWithOnBackgroundThread() {
        
        let expectation = expectationWithDescription("Deferred is completed")
        
        let deferred = Deferred.completed(42)
        
        promise.deferred.onComplete { result in
            XCTAssertEqual(result, 42)
            expectation.fulfill()
        }
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            self.promise.completeWith(deferred)
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK:- tryComplete
    
    func testTryComplete() {
        
        XCTAssertTrue(promise.tryComplete(42))
        XCTAssertFalse(promise.tryComplete(10))
        
        let expectation = expectationWithDescription("Deferred is completed")
        
        promise.deferred.onComplete {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK:- tryCompleteWith
    
    func testTryCompleteWith() {
        
        let exp1 = expectationWithDescription("First deferred is completed")
        
        promise.tryCompleteWith(deferred {
            sleep(1)
            return 10
        }.onComplete { _ in
            exp1.fulfill()
        })
        
        promise.tryCompleteWith(Deferred.completed(42))
        
        let resultExp = expectationWithDescription("Result deferred is completed")
        
        promise.deferred.onComplete {
            XCTAssertEqual($0, 42)
            resultExp.fulfill()
        }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
}
