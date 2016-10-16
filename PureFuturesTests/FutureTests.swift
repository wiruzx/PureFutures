//
//  FutureTests.swift
//  PureFutures
//
//  Created by Victor Shamanov on 4/7/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import XCTest

import PureFutures
import enum Result.Result

class FutureTests: XCTestCase {
    
    enum VoidError: Error {}
    
    var promise: Promise<Int, NSError>!
    let error = NSError(domain: "FutureTests", code: 0, userInfo: nil)

    override func setUp() {
        super.setUp()
        
        promise = Promise()
    }

    private func futureIsCompleteExpectation() -> XCTestExpectation {
        return expectation(description:"Future is completed")
    }
    
    // MARK:- future
    
    func testFutureWithDefaultExecutionContext() {
        
        let f = future { Result<Int, VoidError>.success(42) }
        
        let expectation = futureIsCompleteExpectation()
        
        f.onSuccess {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFutureWithExecutionContext() {
        
        let f1: Future<Int, VoidError> = future(ExecutionContext.global(.async)) {
            XCTAssertFalse(Thread.isMainThread)
            return .success(42)
        }
        
        let f2: Future<Int, VoidError> = future(ExecutionContext.main(.async)) {
            XCTAssertTrue(Thread.isMainThread)
            return .success(42)
        }
        
        let firstExpectation = futureIsCompleteExpectation()
        let secondExpectation = futureIsCompleteExpectation()
        
        f1.onSuccess {
            XCTAssertEqual($0, 42)
            firstExpectation.fulfill()
        }
        
        f2.onSuccess {
            XCTAssertEqual($0, 42)
            secondExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- isCompleted
    
    func testIsCompleted() {
        promise.success(42)
        XCTAssertTrue(promise.future.isCompleted)
    }
    
    func testIsCompletedFalse() {
        XCTAssertFalse(promise.future.isCompleted)
    }
    
    // MARK:- onComplete
    
    func testOnCompleteImmediate() {
        
        promise.complete(Result.success(42))
        
        let expectation = futureIsCompleteExpectation()
        
        promise.future.onComplete { result in
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value!, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testOnCompleteAfterSomeTime() {
        
        let expectation = futureIsCompleteExpectation()
        
        promise.future.onComplete { result in
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value!, 42)
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            sleep(1)
            self.promise.complete(Result.success(42))
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testOnCompleteOnMainThread() {
        
        DispatchQueue.global().async {
            self.promise.complete(Result.success(42))
        }
        
        let expectation = futureIsCompleteExpectation()
        
        promise.future.onComplete(ExecutionContext.main(.async)) { result in
            XCTAssertTrue(Thread.isMainThread)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value!, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testOnCompleteOnBackgroundThread() {
        
        DispatchQueue.global().async {
            self.promise.complete(Result.success(42))
        }
        
        let expectation = futureIsCompleteExpectation()
        
        promise.future.onComplete(ExecutionContext.global(.async)) { result in
            XCTAssertFalse(Thread.isMainThread)
            XCTAssertNotNil(result.value)
            XCTAssertEqual(result.value!, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- onSuccess
    
    func testOnSuccess() {
        
        promise.success(42)
        
        let expectation = futureIsCompleteExpectation()
        
        let future = promise.future
        
        future.onSuccess { value in
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        future.onError { _ in
            XCTFail("Future is failed")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- onError
    
    func testOnError() {
        
        promise.error(error)
        
        let expectation = futureIsCompleteExpectation()
        
        let future = promise.future
        
        future.onError { error in
            XCTAssertEqual(error, self.error)
            expectation.fulfill()
        }
        
        future.onSuccess { _ in
            XCTFail("Future should not be succeed")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- forced
    
    func testForcedCompleted() {
        let future = Future<Int, VoidError>.succeed(42)
        
        if let value = future.forced(1)?.value {
            XCTAssertEqual(value, 42)
        } else {
            XCTFail("result is nil")
        }
    }
    
    func testForcedWithInterval() {
        
        DispatchQueue.global().async {
            self.promise.success(42)
        }
        
        if let value = promise.future.forced(2)?.value {
            XCTAssertEqual(value, 42)
        } else {
            XCTFail("result is nil")
        }
    }
    
    func testForcedWithIntervalOnBackgroundThread() {
        
        DispatchQueue.main.async {
            sleep(1)
            self.promise.success(42)
        }
        
        let expectation = futureIsCompleteExpectation()
        
        DispatchQueue.global().async {
            if let value = self.promise.future.forced(2)?.value {
                XCTAssertEqual(value, 42)
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
            self.promise.success(42)
        }
        
        let result = promise.future.forced()
        
        XCTAssertNotNil(result.value)
        XCTAssertEqual(result.value!, 42)
    }
    
    // MARK:- transform
    
    func testTransformingSucceed() {
        
        let future = Future<Int, NSError>.succeed(42)
        
        let result: Future<Int, NSError> = future.transform(s: {
            $0 / 2
        }, e: { e in
            XCTFail("Error handler should not be called")
            return e
        })
        
        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess { value in
            XCTAssertEqual(value, 42 / 2)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testTransformingFailed() {
        
        let future = Future<Int, NSError>.failed(error)
        
        let result = future.transform(s: { _ in
            XCTFail("This should not be called")
        }, e: { error in
            return NSError(domain: "FutureTests", code: 1, userInfo: nil)
        })
        
        let expectation = futureIsCompleteExpectation()
        
        result.onError { error in
            XCTAssertEqual(error.code, 1)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- map
    
    func testMappingSucceed() {
        
        let future = Future<Int, NSError>.succeed(42)
        
        let result = future.map { $0 / 2 }
        
        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess { value in
            XCTAssertEqual(value, 42 / 2)
            expectation.fulfill()
        }
        
        result.onError { _ in
            XCTFail("This should not be called")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testMappingFailed() {
        
        let future = Future<Int, NSError>.failed(error)
        
        let result = future.map { _ in XCTFail("This should not be called") }
        
        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess { _ in
            XCTFail("This should not be called")
            expectation.fulfill()
        }
        
        result.onError { error in
            XCTAssertEqual(error, self.error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- flatMap
    
    func testFlatMap() {
        
        let future = Future<Int, VoidError>.succeed(42)
        
        let result = future.flatMap { Future.succeed($0 / 2) }
        
        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess { value in
            XCTAssertEqual(value, 42 / 2)
            expectation.fulfill()
        }
        
        result.onError { _ in
            XCTFail("This should not be called")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testFlatMapWithError() {
        
        let future = Future<Int, NSError>.failed(error)
        
        let expectation = futureIsCompleteExpectation()
        
        let result = future.flatMap { value -> Future<Int, NSError> in
            XCTFail("this should not be called")
            expectation.fulfill()
            return Future.succeed(value / 2)
        }
        
        result.onSuccess { _ in
            XCTFail("This should not be called")
            expectation.fulfill()
        }
        
        result.onError { error in
            XCTAssertEqual(error, self.error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    // MARK:- flatten
    
    func testFlatten() {
        
        typealias NestedFuture = Future<Future<Int, VoidError>, VoidError>
        
        let future = NestedFuture.succeed(Future.succeed(42))
        
        let flat = future.flatten()
        
        let expectation = futureIsCompleteExpectation()
        
        flat.onSuccess {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFlattenFailed() {
        
        typealias NestedFuture = Future<Future<Int, NSError>, NSError>
        
        let future = NestedFuture.failed(error)
        
        let flat = future.flatten()
        
        let expectation = futureIsCompleteExpectation()
        
        flat.onError {
            XCTAssertEqual($0, self.error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    
    func testFlattenWithInnerFailed() {
        
        typealias NestedFuture = Future<Future<Int, NSError>, NSError>
        
        let future = NestedFuture.succeed(Future.failed(error))
        
        let flat = future.flatten()
        
        let expectation = futureIsCompleteExpectation()
        
        flat.onError {
            XCTAssertEqual($0, self.error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- zip
    
    func testZip() {
        
        let first = Future<Int, NSError>.succeed(0)
        let second = Future<Int, NSError>.succeed(42)
        
        let result = first.zip(second)
        
        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess { first, second in
            XCTAssertEqual(first, 0)
            XCTAssertEqual(second, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testZipWithFailed() {
        
        let succeed = Future<Int, NSError>.succeed(42)
        let failed = Future<Int, NSError>.failed(error)
        
        let result = succeed.zip(failed)
        
        let expectation = futureIsCompleteExpectation()
        
        result.onError { error in
            XCTAssertEqual(error, self.error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testZipMap() {
        
        let future = Future<Int, NSError>.succeed(42)
        let result = future.zipMap { "\($0)" }

        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess { a, b in
            XCTAssertEqual(a, 42)
            XCTAssertEqual(b, "42")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    // MARK:- reduce
    
    func testReduce() {
        
        let result = Array(1...9).map { Future<Int, NSError>.succeed($0) }.reduce(initial: 0, combine: +)
        
        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess { value in
            XCTAssertEqual(value, 45)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testReduceWithFailed() {
        
        var futures = Array(1...9).map { Future<Int, NSError>.succeed($0) }
        futures.append(.failed(error))
        
        let result = futures.reduce(initial: 0, combine: +)
        
        let expectation = futureIsCompleteExpectation()
        
        result.onError { error in
            XCTAssertEqual(error, self.error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- traverse
    
    func testTraverse() {
        
        let result = Array(1...9).traverse { Future<Int, NSError>.succeed($0 + 1) }
        
        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess { value in
            XCTAssertEqual(value, Array(2...10))
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testTraverseWithFailed() {
        
        let result = Array(1...9).traverse { value -> Future<Int, NSError> in
            value == 9 ? .failed(self.error) : .succeed(value + 1)
        }
        
        let expectation = futureIsCompleteExpectation()
        
        result.onError { error in
            XCTAssertEqual(error, self.error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- sequence
    
    func testSequence() {
        
        let result = Array(1...9).map { Future<Int, NSError>.succeed($0) }.sequence()
        
        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess { value in
            XCTAssertEqual(value, Array(1...9))
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSequenceWithFailed() {
        
        let result = Array(1...9).map { value in return value == 9 ? Future.failed(self.error) : Future.succeed(value) }.sequence()
        
        let expectation = futureIsCompleteExpectation()
        
        result.onError { error in
            XCTAssertEqual(error, self.error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- recover
    
    func testRecoverFailed() {
        
        let failedFuture = Future<Int, NSError>.failed(error)
        
        let recovered = failedFuture.recover { error in
            XCTAssertEqual(error, self.error)
            return 42
        }
        
        let expectation = futureIsCompleteExpectation()
        
        recovered.onSuccess { value in
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRecoverSucceed() {
        
        let future = Future<Int, NSError>.succeed(42)
        
        let recovered = future.recover { _ in
            XCTFail("This should not be called")
            return 0
        }
        
        let expectation = futureIsCompleteExpectation()
        
        recovered.onSuccess { value in
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- recoverWith
    
    func testRecoverFailedWith() {
        
        let failedFuture = Future<Int, NSError>.failed(error)
        
        let recovered = failedFuture.recoverWith { error in
            XCTAssertEqual(error, self.error)
            return Future.succeed(42)
        }
        
        let expectation = futureIsCompleteExpectation()
        
        recovered.onSuccess { value in
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRecoverSucceedWith() {
        
        let future = Future<Int, NSError>.succeed(42)
        
        let recovered = future.recoverWith { _ in
            XCTFail("This should not be called")
            return Future.succeed(0)
        }
        
        let expectation = futureIsCompleteExpectation()
        
        recovered.onSuccess { value in
            XCTAssertEqual(value, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- toDeferred
    
    func testToDeferredWithoutRecovering() {
        let future = Future<Int, NSError>.succeed(42)
        
        let deferred = future.toDeferred()
        
        let expectation = futureIsCompleteExpectation()
        
        deferred.onComplete { result in
            switch result {
            case .success(let value):
                XCTAssertEqual(value, 42)
            case .failure(_):
                XCTFail("an error occured")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testToDeferred() {
        
        let future = Future<Int, NSError>.succeed(42)
        
        let deferred = future.toDeferred { _ in 0 }
        
        let expectation = futureIsCompleteExpectation()
        
        deferred.onComplete {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testToDeferredWithError() {
        let future = Future<Int, NSError>.failed(error)
        
        let deferred = future.toDeferred { _ in 42 }
        
        let expectation = futureIsCompleteExpectation()
        
        deferred.onComplete {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK:- ?? operator
    
    func testCoalescingToDeferredWithSucceed() {
        
        let future = Future<Int, VoidError>.succeed(42)
        
        let deferred = future ?? 10
        
        let expectation = futureIsCompleteExpectation()
        
        deferred.onComplete {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCoalescingToDeferredWithFailed() {
        
        let future = Future<Int, NSError>.failed(error)
        
        let deferred = future ?? 42
        
        let expectation = futureIsCompleteExpectation()
        
        deferred.onComplete {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
        
    }
    
    func testCoalescingToFutureWithFirstSucceed() {
        
        let first = Future<Int, NSError>.succeed(42)
        let second = Future<Int, NSError>.failed(error)
        
        let result = first ?? second
        
        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCoalescingToFutureWithFirstFailed() {
        
        let first = Future<Int, NSError>.failed(error)
        let second = Future<Int, NSError>.succeed(42)
        
        let result = first ?? second
        
        let expectation = futureIsCompleteExpectation()
        
        result.onSuccess {
            XCTAssertEqual($0, 42)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCoalescingToFutureWithBothFailed() {
     
        let first = Future<Int, NSError>.failed(NSError(domain: "", code: 0, userInfo: nil))
        let second = Future<Int, NSError>.failed(error)
        
        let result = first ?? second
        
        let expectation = futureIsCompleteExpectation()
        
        result.onError { error in
            XCTAssertEqual(error, self.error)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)   
    }
    
    // MARK: - retry 
    
    func testRetryWhenNoSuccessValues() {
        
        enum TestError: Error {
            case first, second
        }
        
        let values: [Result<Int, TestError>] = [.failure(.first), .failure(.first), .failure(.second), .success(10)]
        
        var valuesGenerator = values.makeIterator()
        
        let exp = futureIsCompleteExpectation()
        
        let result = Future.retry(count: 3) { .completed(valuesGenerator.next()!) }
        
        result.onError { error in
            XCTAssert(error == .second)
            exp.fulfill()
        }.onSuccess { _ in
            XCTFail()
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRetyWithSuccessValue() {
        
        struct TestError: Error {}
        
        let values: [Result<Int, TestError>] = [.failure(.init()), .failure(.init()), .success(10), .success(20)]
        var valueGenerator = values.makeIterator()
        
        let exp = futureIsCompleteExpectation()
        
        Future.retry(count: 4) { Future.completed(valueGenerator.next()!) }
            .onSuccess {
                XCTAssertEqual($0, 10)
            }.onError { _ in
                XCTFail()
            }.onComplete { _ in
                exp.fulfill()
            }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRetryWithLastSuccessValue() {
        
        struct TestError: Error {}
        
        let values: [Result<Int, TestError>] = [.failure(.init()), .failure(.init()), .success(10)]
        var valueGenerator = values.makeIterator()
        
        let exp = futureIsCompleteExpectation()
        
        Future.retry(count: 3) { Future.completed(valueGenerator.next()!) }
            .onSuccess {
                XCTAssertEqual($0, 10)
            }.onError { _ in
                XCTFail()
            }.onComplete { _ in
                exp.fulfill()
            }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRetryWithFisrtSuccess() {
        
        struct TestError: Error {}
        
        let values: [Result<Int, TestError>] = [.success(10)]
        var valueGenerator = values.makeIterator()
        
        let exp = futureIsCompleteExpectation()
        
        Future.retry(count: 2) { Future.completed(valueGenerator.next()!) }
            .onSuccess {
                XCTAssertEqual($0, 10)
            }.onError { _ in
                XCTFail()
            }.onComplete { _ in
                exp.fulfill()
            }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    
}
