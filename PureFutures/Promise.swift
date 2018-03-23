//
//  Promise.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import enum Result.Result
import protocol Result.ResultProtocol

/**

    A mutable container for the `Future`

    Allows you complete `Future` that it holds

*/
public final class Promise<T, E: Error> {
    
    // MARK:- Public properties

    /// `Future` which Promise will complete
    public let future = Future<T, E>()

    /// Shows if its future is completed
    public var isCompleted: Bool {
        return future.isCompleted
    }
    
    // MARK:- Initialization
    
    public init() {
    }
    
    // MARK:- PromiseType methods

    /**

        Completes Promise's future with given `value`

        Should be called only once! Second and next calls will raise an exception
    
        See also: `tryComplete`
    
        - parameter value: value, that future will be completed with

    */
    public func complete<R: ResultProtocol>(_ value: R) where R.Value == T, R.Error == E {
        future.setValue(value)
    }

    /**

        Completes Promise's future with given `future`

        Should be called only once! Second and next calls will raise an exception
    
        See also: `tryCompleteWith`
    
        - parameter future: Value that conforms to `FutureType` protocol

    */
    public func completeWith<F: FutureType>(_ future: F) where F.Value.Value == T, F.Value.Error == E {
        future.onComplete { self.complete($0) }
    }

    /**
        Complete Promise's future with given success `value`

        Should be called only once! Second and next calls will raise an exception
    
        See also: `trySuccess`

        - parameter value: value, that future will be succeed with

    */
    public func success(_ value: T) {
        complete(Result.success(value))
    }
    
    /**
        Complete Promise's future with given `error`

        Should be called only once! Second and next calls will raise an exception

        See also: `tryError`

        - parameter error: error, that future will be succeed with

    */
    public func error(_ error: E) {
        complete(Result.failure(error))
    }
    
    // MARK:- Other methods

    /**

        Tries to complete Promise's future with given `value`

        If future has already completed returns `false`, otherwise returns `true`

        See also: `complete`

        - parameter value: result that future will be completed with

        - returns: Bool which says if completing was successful or not

    */
    @discardableResult
    public func tryComplete<R: ResultProtocol>(_ value: R) -> Bool where R.Value == T, R.Error == E {
        if isCompleted {
            return false
        } else {
            complete(value)
            return true
        }
    }

    /**

        Tries to complete Promise's future with given success `value`

        If future has already completed returns `flase`, otherwise returns `true`

        See also: `success`

        - parameter value: a success value that future will be completed with

        - returns: Bool which says if completing was successful or not

    */
    @discardableResult
    public func trySuccess(_ value: T) -> Bool {
        return tryComplete(Result.success(value))
    }

    /**

        Tries to complete Promise's future with given success `value`

        If future has already completed returns `flase`, otherwise returns `true`

        See also: `success`

        - parameter error: an error that future will be completed with

        - returns: Bool which says if completing was successful or not

    */
    @discardableResult
    public func tryError(_ error: E) -> Bool {
        return tryComplete(Result.failure(error))
    }

    /**

        Tries to complete Promise's future with given future

        If future has already completed returns `flase`, otherwise returns `true`

        See also: `completeWith`

        - parameter future: a future value that future will be completed with

        - returns: Bool which says if completing was successful or not

    */
    @discardableResult
    public func tryCompleteWith<F: FutureType>(_ future: F) -> Bool where F.Value.Value == T, F.Value.Error == E {
        if isCompleted {
            return false
        }
        future.onComplete { self.tryComplete($0) }
        return true
    }
    
}
