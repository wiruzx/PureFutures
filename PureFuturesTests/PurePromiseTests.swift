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
        
        let exp = expectation(description:"Deferred is completed")
        
        promise.deferred.onComplete { result in
            XCTAssertEqual(result, 42)
            exp.fulfill()
        }
        
        promise.complete(42)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCompleteOnBackgroundThread() {
        let exp = expectation(description:"Deferred is completed")
        
        promise.deferred.onComplete { result in
            XCTAssertEqual(result, 42)
            exp.fulfill()
        }
        
        DispatchQueue.global().async {
            self.promise.complete(42)
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
    }
    
    // MARK:- completeWith
    
    func testCompleteWith() {
        
        let exp = expectation(description:"Deferred is completed")
        
        let deferred = Deferred.completed(42)
        
        promise.deferred.onComplete { result in
            XCTAssertEqual(result, 42)
            exp.fulfill()
        }
        
        promise.completeWith(deferred)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCompleteWithOnBackgroundThread() {
        
        let exp = expectation(description:"Deferred is completed")
        
        let deferred = Deferred.completed(42)
        
        promise.deferred.onComplete { result in
            XCTAssertEqual(result, 42)
            exp.fulfill()
        }
        
        DispatchQueue.global().async {
            self.promise.completeWith(deferred)
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- tryComplete
    
    func testTryComplete() {
        
        XCTAssertTrue(promise.tryComplete(42))
        XCTAssertFalse(promise.tryComplete(10))
        
        let exp = expectation(description:"Deferred is completed")
        
        promise.deferred.onComplete {
            XCTAssertEqual($0, 42)
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- tryCompleteWith
    
    func testTryCompleteWith() {
        
        let exp1 = expectation(description:"First deferred is completed")
        
        promise.tryCompleteWith(deferred {
            sleep(1)
            return 10
        }.onComplete { _ in
            exp1.fulfill()
        })
        
        promise.tryCompleteWith(Deferred.completed(42))
        
        let resultExp = expectation(description:"Result deferred is completed")
        
        promise.deferred.onComplete {
            XCTAssertEqual($0, 42)
            resultExp.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
}
