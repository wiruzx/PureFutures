//
//  PromiseTests.swift
//  PureFutures
//
//  Created by Victor Shamanov on 4/22/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import XCTest

import struct PureFutures.Promise
import enum PureFutures.Result
import enum PureFutures.ExecutionContext
import class PureFutures.Future

class PromiseTests: XCTestCase {
    
    var promise: Promise<Int, String>!
    
    override func setUp() {
        super.setUp()
        
        promise = Promise()
    }
    
    // MARK:- isCompleted
    
    func testIsCompleted() {
        promise.success(42)
        XCTAssertTrue(promise.isCompleted)
    }
    
    func testIsCompletedFalse() {
        XCTAssertFalse(promise.isCompleted)
    }
    
    // MARK:- complete
    
    func testComplete() {
        
        let expectation = expectationWithDescription("Future is completed")
        
        promise.future.onComplete { result in
            if let value = result.value {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("vlaue is nil")
            }
            
            expectation.fulfill()
        }
        
        promise.complete(Result(42))
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testCompleteOnBackgroundThread() {
        
        let expectation = expectationWithDescription("Future is completed")
        
        promise.future.onComplete { result in
            if let value = result.value {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("vlaue is nil")
            }
            
            expectation.fulfill()
        }
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            self.promise.complete(Result(42))
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
        
    }
    
    // MARK:- completeWith
    
    func testCompleteWith() {
        
        let expectation = expectationWithDescription("Future is completed")
        
        promise.future.onComplete { result in
            if let value = result.value {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("vlaue is nil")
            }
            
            expectation.fulfill()
        }
        
        promise.completeWith(Future.succeed(42))
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testCompleteWithOnBackgroundThread() {
        
        let expectation = expectationWithDescription("Future is completed")
        
        promise.future.onComplete { result in
            if let value = result.value {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("vlaue is nil")
            }
            
            expectation.fulfill()
        }
        
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            self.promise.completeWith(Future.succeed(42))
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
        
    }
    
    // MARK:- testSuccess
    
    func testSuccess() {
        
        let expectation = expectationWithDescription("Future is completed")
        
        promise.future.onComplete { result in
            if let value = result.value {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("vlaue is nil")
            }
            
            expectation.fulfill()
        }
        
        promise.success(42)
        
        waitForExpectationsWithTimeout(1, handler: nil)
        
    }
    
    // MARK:- testError
    
    func testError() {
        
        let expectation = expectationWithDescription("Future is completed")
        
        promise.future.onComplete { result in
            
            switch result {
            case .Success(_):
                XCTFail("This should not be called")
            case .Error(let box):
                XCTAssertEqual(box.value, "An error message")
            }
            
            expectation.fulfill()
        }
        
        promise.error("An error message")
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
}
