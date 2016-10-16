//
//  PromiseTests.swift
//  PureFutures
//
//  Created by Victor Shamanov on 4/22/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import XCTest

import PureFutures
import enum Result.Result

class PromiseTests: XCTestCase {
    
    enum TestErrorType: Error {
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
        
        let exp = expectation(description:"Future is completed")
        
        promise.future.onComplete { result in
            if let value = result.value {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("vlaue is nil")
            }
            
            exp.fulfill()
        }
        
        promise.complete(Result.success(42))
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCompleteOnBackgroundThread() {
        
        let exp = expectation(description: "Future is completed")
        
        promise.future.onComplete { result in
            if let value = result.value {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("vlaue is nil")
            }
            
            exp.fulfill()
        }
        
        DispatchQueue.global().async {
            self.promise.complete(Result.success(42))
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
    }
    
    // MARK:- completeWith
    
    func testCompleteWith() {
        
        let exp = expectation(description: "Future is completed")
        
        promise.future.onComplete { result in
            if let value = result.value {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("vlaue is nil")
            }
            
            exp.fulfill()
        }
        
        promise.completeWith(Future.succeed(42))
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCompleteWithOnBackgroundThread() {
        
        let exp = expectation(description: "Future is completed")
        
        promise.future.onComplete { result in
            if let value = result.value {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("vlaue is nil")
            }
            
            exp.fulfill()
        }
        
        DispatchQueue.global().async {
            self.promise.completeWith(Future.succeed(42))
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
    }
    
    // MARK:- testSuccess
    
    func testSuccess() {
        
        let exp = expectation(description:"Future is completed")
        
        promise.future.onComplete { result in
            if let value = result.value {
                XCTAssertEqual(value, 42)
            } else {
                XCTFail("vlaue is nil")
            }
            
            exp.fulfill()
        }
        
        promise.success(42)
        
        waitForExpectations(timeout: 1, handler: nil)
        
    }
    
    // MARK:- testError
    
    func testError() {
        
        let exp = expectation(description:"Future is completed")
        
        promise.future.onComplete { result in
            
            switch result {
            case .success(_):
                XCTFail("This should not be called")
            case .failure(let error):
                XCTAssertEqual(error, TestErrorType.Error1)
            }
            
            exp.fulfill()
        }
        
        promise.error(.Error1)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- tryComlete
    
    func testTryComplete() {
        
        XCTAssertTrue(promise.tryComplete(Result.success(42)))
        XCTAssertFalse(promise.tryComplete(Result.success(10)))
        
        let exp = expectation(description:"Future is copleted")
        
        promise.future.onComplete {
            switch $0 {
            case .success(let value):
                XCTAssertEqual(value, 42)
            case .failure(_):
                XCTFail("Result should not be error")
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- trySuccess 
    
    func testTrySuccess() {
        
        XCTAssertTrue(promise.trySuccess(42))
        XCTAssertFalse(promise.trySuccess(10))
        
        let exp = expectation(description:"Future is copleted")
        
        promise.future.onComplete {
            switch $0 {
            case .success(let value):
                XCTAssertEqual(value, 42)
            case .failure(_):
                XCTFail("Result should not be error")
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
    }
    
    // MARK:- tryError
    
    func testTryError() {
        
        XCTAssertTrue(promise.tryError(.Error1))
        XCTAssertFalse(promise.tryError(.Error2))
        
        let exp = expectation(description:"Future is copleted")
        
        promise.future.onComplete {
            switch $0 {
            case .success(_):
                XCTFail("Result should not be a value")
            case .failure(let error):
                XCTAssertEqual(error, TestErrorType.Error1)
            }
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- tryCompleteWith
    
    func testTryCompleteWith() {
        
        let firstExp = expectation(description:"First Future is completed")
        
        promise.tryCompleteWith(future {
            sleep(1)
            return .success(10)
        }.onComplete { _ in
            firstExp.fulfill()
        })
        
        promise.tryCompleteWith(Future.completed(.success(42)))
        
        let resultExp = expectation(description:"Result Future is copleted")
        
        promise.future.onComplete {
            switch $0 {
            case .success(let value):
                XCTAssertEqual(value, 42)
            case .failure(_):
                XCTFail("Result should not be error")
            }
            resultExp.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
}
