//
//  Future.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import typealias Foundation.NSTimeInterval
import class Foundation.NSError

import enum Result.Result
import protocol Result.ResultProtocol
import func Result.materialize

// MARK:- Future

/**

    Represents a value that will be available in the future

    This value is usually result of some computation or network request.

    May completes with either `Success` and `Error` cases

    This is convenient way to use `Deferred<Result<T, E>>`

    See also: `Deferred`

*/

public final class Future<T, E: Error>: FutureType {
    
    // MARK:- Type declarations
    
    public typealias Value = Result<T, E>
    
    public typealias CompleteCallback = (Value) -> Void
    public typealias SuccessCallback = (T) -> Void
    public typealias ErrorCallback = (E) -> Void
    
    // MARK:- Private properties
    
    private let deferred: Deferred<Value>
    
    // MARK:- Public properties

    /// Value of Future
    public private(set) var value: Value? {
        set {
            deferred.setValue(newValue!)
        }
        get {
            return deferred.value
        }
    }

    /// Shows if Future is completed
    public var isCompleted: Bool {
        return deferred.isCompleted
    }
    
    // MARK:- Initialization
    
    internal init() {
        deferred = Deferred()
    }
    
    internal init(deferred: Deferred<Value>) {
        self.deferred = deferred
    }
    
    public init<F: FutureType>(future: F) where F.Value.Value == T, F.Value.Error == E {
        deferred = future.map { Result(result: $0) }
    }
    
    // MARK:- Class methods

    /**
    
        Returns a new immediately completed `Future<T, E>` with given `value`

        - parameter value: value which Future will have

        - returns: a new Future

    */
    public class func succeed(_ value: T) -> Future {
        return .completed(.success(value))
    }


    /**

        Returns a new immediately completed `Future<T, E>` with given `error`

        - parameter error: error which Future will have

        - returns: a new Future
        
    */
    public class func failed(_ error: E) -> Future {
        return .completed(.failure(error))
    }
    
    /// Creates a new Future with given Result<T, E>
    public static func completed(_ x: Value) -> Future {
        return Future(deferred: .completed(x))
    }

    // MARK:- FutureType methods

    /**

        Register a callback which will be called when Future is completed

        - parameter ec: execution context of callback
        - parameter c: callback

        - returns: Returns itself for chaining operations
        
    */
    @discardableResult
    public func onComplete(_ c: @escaping CompleteCallback) -> Future {
        deferred.onComplete(c)
        return self
    }

    // MARK:- Internal methods
    
    internal func setValue<R: ResultProtocol>(_ value: R) where R.Value == T, R.Error == E {
        self.value = Result(result: value)
    }
    
}
