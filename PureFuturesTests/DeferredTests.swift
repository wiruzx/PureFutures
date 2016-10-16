//
//  DeferredTests.swift
//  PureFutures
//
//  Created by Victor Shamanov on 3/7/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import XCTest

import PureFutures

class DeferredTests: XCTestCase {
    
    var promise: PurePromise<Int>!

    override func setUp() {
        super.setUp()
        
        promise = PurePromise()
    }
    
    private func deferredIsCompleteExpectation() -> XCTestExpectation {
        return expectation(description:"Deferred is completed")
    }
    
    // MARK:- deferred
    
    func testDeferredWithDefaultExecutionContext() {
        
        let def = deferred { 42 }
        
        let expectation = deferredIsCompleteExpectation()
        
        def.onComplete {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testDeferredWithMainThreadExecutionContext() {
        
        let d1: Deferred<Int> = deferred(ExecutionContext.main(.async)) {
            XCTAssertTrue(Thread.isMainThread)
            return 42
        }
        
        let d2: Deferred<Int> = deferred(ExecutionContext.global(.async)) {
            XCTAssertFalse(Thread.isMainThread)
            return 42
        }
        
        let firstDeferredExpectation = deferredIsCompleteExpectation()
        let secondDeferredExpectation = deferredIsCompleteExpectation()
        
        d1.onComplete {
            XCTAssertEqual($0, 42)
            firstDeferredExpectation.fulfill()
        }
        
        d2.onComplete {
            XCTAssertEqual($0, 42)
            secondDeferredExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- isCompleted
    
    func testIsCompleted() {
        promise.complete(42)
        XCTAssertTrue(promise.deferred.isCompleted)
    }
    
    func testIsCompletedFalse() {
        XCTAssertFalse(promise.deferred.isCompleted)
    }
    
    // MARK:- onComplete
    
    func testOnCompleteImmediate() {
        
        self.promise.complete(42)
        
        let expectation = deferredIsCompleteExpectation()
        
        self.promise.deferred.onComplete { value in
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testOnCompleteAfterSomeTime() {
        
        let expectation = deferredIsCompleteExpectation()
        
        self.promise.deferred.onComplete { value in
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            sleep(1)
            self.promise.complete(42)
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testOnCompleteOnMainThread() {
        
        DispatchQueue.global().async {
            self.promise.complete(42)
        }
        
        let expectation = deferredIsCompleteExpectation()
        
        self.promise.deferred.onComplete(ExecutionContext.main(.async)) { value in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testOnCompleteOnBackgroundThread() {
        
        DispatchQueue.global().async {
            self.promise.complete(42)
        }
        
        let expectation = deferredIsCompleteExpectation()
        
        self.promise.deferred.onComplete(ExecutionContext.global(.async)) { value in
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
    }
    
    func testOnCompleteExecutionOrder() {
        
        var result: [Int] = []
        let p: PurePromise<Void> = .init()
        let deferred = p.deferred
        
        deferred.onComplete {
            result.append(1)
        }
        
        deferred.onComplete {
            result.append(2)
        }
        
        deferred.onComplete {
            result.append(3)
        }
        
        let exp = expectation(description:"Deferred is completed")
        
        deferred.onComplete {
            XCTAssertEqual(result, [1, 2, 3])
            exp.fulfill()
        }
        
        p.complete()
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testOnCompleteExecutionOrderWithCompletedDeferred() {
        
        var result: [Int] = []
        let deferred: Deferred<Void> = .completed()
        
        deferred.onComplete {
            result.append(1)
        }
        
        deferred.onComplete {
            result.append(2)
        }
        
        deferred.onComplete {
            result.append(3)
        }
        
        let exp = expectation(description:"Deferred is completed")
        
        deferred.onComplete {
            XCTAssertEqual(result, [1, 2, 3])
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    // MARK:- forced
    
    func testForcedCompleted() {
        
        let deferred = Deferred.completed(42)
        
        if let result = deferred.forced(1) {
            XCTAssertEqual(result, 42)
        } else {
            XCTFail("Result is nil")
        }
    }
    
    func testForcedWithInterval() {
        
        DispatchQueue.global().async {
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
        
        DispatchQueue.main.async {
            sleep(1)
            self.promise.complete(42)
        }
        
        let expectation = deferredIsCompleteExpectation()
        
        DispatchQueue.global().async {
            if let result = self.promise.deferred.forced(2) {
                XCTAssertEqual(result, 42)
            } else {
                XCTFail("result is nil")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
        
    }
    
    func testForcedInfinite() {
        
        DispatchQueue.global().async {
            sleep(1)
            self.promise.complete(42)
        }
        
        let result = promise.deferred.forced()
        
        XCTAssertEqual(result, 42)
        
    }
    
    // MARK:- map
    
    func testMap() {
        
        let deferred = Deferred.completed(42)
        
        let result = deferred.map { $0 * 2 }
        
        let expectation = deferredIsCompleteExpectation()
        
        result.onComplete { value in
            
            XCTAssertEqual(value, 42 * 2)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
    }
    
    // MARK:- flatMap
    
    func testFlatMap() {
        
        let deferred = Deferred.completed(42)
        
        let result = deferred.flatMap { x in Deferred.completed(x * 2) }
        
        let expectation = deferredIsCompleteExpectation()
        
        result.onComplete { value in
            
            XCTAssertEqual(value, 42 * 2)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- flatten
    
    func testFlattenTemp() {
        
        let deferred = Deferred.completed(Deferred.completed(42))
        
        func f(def: Deferred<Int>) -> Int {
            return def.forced()
        }
        
    }
    
    func testFlatten() {
        
        let deferred = Deferred.completed(Deferred.completed(42))
        
        let flat = deferred.flatten()
        
        let expectation = deferredIsCompleteExpectation()
        
        flat.onComplete {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- zip
    
    func testZip() {
        
        let first = Deferred.completed(0)
        let second = Deferred.completed(42)
        
        let result = first.zip(second)
        
        let expectation = deferredIsCompleteExpectation()
        
        result.onComplete { first, second in
            
            XCTAssertEqual(first, 0)
            XCTAssertEqual(second, 42)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testZipMap() {
        
        let deferred = Deferred.completed(42)

        let result = deferred.zipMap { "\($0)" }

        let expectation = deferredIsCompleteExpectation()

        result.onComplete { a, b in
            XCTAssertEqual(a, 42)
            XCTAssertEqual(b, "42")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    // MARK:- reduce
    
    func testReduce() {
        
        let defs = Array(1...9).map { Deferred.completed($0) }
        
        let result = defs.reduce(initial: 0, combine: +)
        
        let expectation = deferredIsCompleteExpectation()
        
        result.onComplete { value in
            
            XCTAssertEqual(value, 45)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- traverse
    
    func testTraverse() {
        
        let result = Array(1...9).traverse { Deferred.completed($0 + 1) }
        
        let expectation = deferredIsCompleteExpectation()
        
        result.onComplete { value in
            
            XCTAssertEqual(value, Array(2...10))
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- sequence
    
    func testSequence() {
        
        let defs = Array(1...5).map { Deferred.completed($0) }
        
        let result = defs.sequence()
        
        let expectation = deferredIsCompleteExpectation()
        
        result.onComplete { value in
            
            XCTAssertEqual(value, Array(1...5))
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
}
