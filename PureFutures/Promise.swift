//
//  Promise.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import enum Result.Result

/**

    A mutable container for the `Future`

    Allows you complete `Future` that it holds

*/
public final class Promise<T, E: ErrorType> {
    
    // MARK:- Type declarations
    
    typealias Element = Result<T, E>
    
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
    public func complete(value: Result<T, E>) {
        future.setValue(value)
    }

    /**

        Completes Promise's future with given `future`

        Should be called only once! Second and next calls will raise an exception
    
        See also: `tryCompleteWith`
    
        - parameter future: Value that conforms to `FutureType` protocol

    */
    public func completeWith<F: FutureType where F.Success == T, F.Error == E>(future: F) {
        future.onComplete(Pure) { self.complete($0) }
    }

    /**
        Complete Promise's future with given success `value`

        Should be called only once! Second and next calls will raise an exception
    
        See also: `trySuccess`

        - parameter value: value, that future will be succeed with

    */
    public func success(value: T) {
        complete(.Success(value))
    }
    
    /**
        Complete Promise's future with given `error`

        Should be called only once! Second and next calls will raise an exception

        See also: `tryError`

        - parameter error: error, that future will be succeed with

    */
    public func error(error: E) {
        complete(.Failure(error))
    }
    
    // MARK:- Other methods

    /**

        Tries to complete Promise's future with given `value`

        If future has already completed returns `false`, otherwise returns `true`

        See also: `complete`

        - parameter value: result that future will be completed with

        - returns: Bool which says if completing was successful or not

    */
    public func tryComplete(value: Result<T, E>) -> Bool {
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
    public func trySuccess(value: T) -> Bool {
        return tryComplete(.Success(value))
    }

    /**

        Tries to complete Promise's future with given success `value`

        If future has already completed returns `flase`, otherwise returns `true`

        See also: `success`

        - parameter error: an error that future will be completed with

        - returns: Bool which says if completing was successful or not

    */
    public func tryError(error: E) -> Bool {
        return tryComplete(.Failure(error))
    }

    /**

        Tries to complete Promise's future with given future

        If future has already completed returns `flase`, otherwise returns `true`

        See also: `completeWith`

        - parameter future: a future value that future will be completed with

        - returns: Bool which says if completing was successful or not

    */
    public func tryCompleteWith<F: FutureType where F.Success == T, F.Error == E>(future: F) {
        future.onComplete(Pure) { self.tryComplete($0) }
    }
    
}
