//
//  PromiseTests.swift
//  PureFutures
//
//  Created by Victor Shamanov on 4/22/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import XCTest

import class PureFutures.Promise
import enum Result.Result
import enum PureFutures.ExecutionContext
import class PureFutures.Future
import func PureFutures.future

class PromiseTests: XCTestCase {
    
    enum TestErrorType: ErrorType {
        case Error1
        case Error2
    }
    
    var promise: Promise<Int, TestErrorType>!
    
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
        
        promise.complete(Result.Success(42))
        
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
            self.promise.complete(Result.Success(42))
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
            case .Failure(let error):
                XCTAssertEqual(error, TestErrorType.Error1)
            }
            
            expectation.fulfill()
        }
        
        promise.error(.Error1)
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK:- tryComlete
    
    func testTryComplete() {
        
        XCTAssertTrue(promise.tryComplete(Result.Success(42)))
        XCTAssertFalse(promise.tryComplete(Result.Success(10)))
        
        let expectation = expectationWithDescription("Future is copleted")
        
        promise.future.onComplete {
            switch $0 {
            case .Success(let value):
                XCTAssertEqual(value, 42)
            case .Failure(_):
                XCTFail("Result should not be error")
            }
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK:- trySuccess 
    
    func testTrySuccess() {
        
        XCTAssertTrue(promise.trySuccess(42))
        XCTAssertFalse(promise.trySuccess(10))
        
        let expectation = expectationWithDescription("Future is copleted")
        
        promise.future.onComplete {
            switch $0 {
            case .Success(let value):
                XCTAssertEqual(value, 42)
            case .Failure(_):
                XCTFail("Result should not be error")
            }
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
        
    }
    
    // MARK:- tryError
    
    func testTryError() {
        
        XCTAssertTrue(promise.tryError(.Error1))
        XCTAssertFalse(promise.tryError(.Error2))
        
        let expectation = expectationWithDescription("Future is copleted")
        
        promise.future.onComplete {
            switch $0 {
            case .Success(_):
                XCTFail("Result should not be a value")
            case .Failure(let error):
                XCTAssertEqual(error, TestErrorType.Error1)
            }
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK:- tryCompleteWith
    
    func testTryCompleteWith() {
        
        let firstExp = expectationWithDescription("First Future is completed")
        
        promise.tryCompleteWith(future {
            sleep(1)
            return .Success(10)
        }.andThen { _ in
            firstExp.fulfill()
        })
        
        promise.tryCompleteWith(Future.completed(.Success(42)))
        
        let resultExp = expectationWithDescription("Result Future is copleted")
        
        promise.future.onComplete {
            switch $0 {
            case .Success(let value):
                XCTAssertEqual(value, 42)
            case .Failure(_):
                XCTFail("Result should not be error")
            }
            resultExp.fulfill()
        }
        
        waitForExpectationsWithTimeout(2, handler: nil)
    }
    
}
