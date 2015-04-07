//
//  DeferredTests.swift
//  PureFutures
//
//  Created by Victor Shamanov on 3/7/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import XCTest

import class PureFutures.Deferred
import struct PureFutures.PurePromise

class DeferredTests: XCTestCase {
    
    var promise: PurePromise<Int>!

    override func setUp() {
        super.setUp()
        
        promise = PurePromise()
    }
    
    // MARK:- onComplete
    
    func testOnCompleteImmediate() {
        
        self.promise.complete(42)
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        self.promise.deferred.onComplete { value in
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testOnCompleteAfterSomeTime() {
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        self.promise.deferred.onComplete { value in
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            sleep(1)
            self.promise.complete(42)
        }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
    func testOnCompleteOnMainThread() {
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            self.promise.complete(42)
        }
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        self.promise.deferred.onComplete(dispatch_get_main_queue()) { value in
            XCTAssertTrue(NSThread.isMainThread())
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testOnCompleteOnBackgroundThread() {
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            self.promise.complete(42)
        }
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        self.promise.deferred.onComplete(dispatch_get_global_queue(0, 0)) { value in
            XCTAssertFalse(NSThread.isMainThread())
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
        
    }
    
    // MARK:- forced
    
    func testForcedWithInterval() {
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            sleep(1)
            self.promise.complete(42)
        }
        
        if let result = promise.deferred.forced(2) {
            XCTAssertEqual(result, 42)
        } else {
            XCTFail("result is nil")
        }
    }
    
    func testForcedWithIntervalOnBackgroundThred() {
        
        dispatch_async(dispatch_get_main_queue()) {
            sleep(1)
            self.promise.complete(42)
        }
        
        let expectation = expectationWithDescription("Deferred is completed")
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            if let result = self.promise.deferred.forced(2) {
                XCTAssertEqual(result, 42)
            } else {
                XCTFail("result is nil")
            }
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(3, handler: nil)
        
    }
    
    func testForcedInfinite() {
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            sleep(1)
            self.promise.complete(42)
        }
        
        let result = promise.deferred.forced()
        
        XCTAssertEqual(result, 42)
        
    }
    
    // MARK:- map
    
    func testMap() {
        
        let deferred = Deferred(42)
        
        let result = deferred.map { $0 * 2 }
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        result.onComplete { value in
            
            XCTAssertEqual(value, 42 * 2)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
        
    }
    
    // MARK:- flatMap
    
    func testFlatMap() {
        
        let deferred = Deferred(42)
        
        let result = deferred.flatMap { Deferred($0 * 2) }
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        result.onComplete { value in
            
            XCTAssertEqual(value, 42 * 2)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK:- filter
    
    func testFilterPass() {
        
        let deferred = Deferred(42)
        
        let result = deferred.filter { $0 % 2 == 0}
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        result.onComplete {
            
            if let value = $0 {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("Value is nil")
            }

            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testFilterSkip() {
        
        let deferred = Deferred(42)
        
        let result = deferred.filter { $0 % 2 != 0}
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        result.onComplete { value in
            
            XCTAssertNil(value)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK:- zip
    
    func testZip() {
        
        let first = Deferred(0)
        let second = Deferred(42)
        
        let result = first.zip(second)
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        result.onComplete { first, second in
            
            XCTAssertEqual(first, 0)
            XCTAssertEqual(second, 42)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK:- reduce
    
    func testReduce() {
        
        let defs = Array(1...9).map { Deferred($0) }
        
        let result = Deferred.reduce(defs, initial: 0, combine: +)
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        result.onComplete { value in
            
            XCTAssertEqual(value, 45)
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK:- traverse
    
    func testTraverse() {
        
        let xs = Array(1...9)
        
        let result = Deferred.traverse(xs) { Deferred($0 + 1) }
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        result.onComplete { value in
            
            XCTAssertEqual(value, Array(2...10))
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK:- sequence
    
    func testSequence() {
        
        let defs = Array(1...5).map { Deferred($0) }
        
        let result = Deferred.sequence(defs)
        
        let expectation = expectationWithDescription("Deferred is complete")
        
        result.onComplete { value in
            
            XCTAssertEqual(value, Array(1...5))
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
}
