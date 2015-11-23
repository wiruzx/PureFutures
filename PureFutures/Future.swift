//
//  Future.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import typealias Foundation.NSTimeInterval
import enum Result.Result
import protocol Result.ResultType

// MARK:- future creation function

/**

    Creates a new `Future<T, E>` whose value will be
    result of execution `f` on background thread

    - parameter f: function, which result will become value of returned Future

    - returns: a new Future<T, E>
    
*/
public func future<T, E>(f: () -> Result<T, E>) -> Future<T, E> {
    return future(Pure, f: f)
}

/**

    Creates a new `Future<T, E>` whose value will be
    result of execution `f` on `ec` execution context

    - parameter ec: execution context of given function
    - parameter f: function, which result will become value of returned Future

    - returns: a new Future<T, E>
    
*/
public func future<T, E>(ec: ExecutionContextType, f: () -> Result<T, E>) -> Future<T, E> {
    let p = Promise<T, E>()
    
    ec.execute {
        p.complete(f())
    }
    
    return p.future
}

// MARK:- Future

/**

    Represents a value that will be available in the future

    This value is usually result of some computation or network request.

    May completes with either `Success` and `Error` cases

    This is convenient way to use `Deferred<Result<T, E>>`

    See also: `Deferred`

*/

public final class Future<T, E: ErrorType>: FutureType {
    
    // MARK:- Type declarations
    
    public typealias Element = Result<T, E>
    
    public typealias CompleteCallback = Element -> Void
    public typealias SuccessCallback = T -> Void
    public typealias ErrorCallback = E -> Void
    
    // MARK:- Private properties
    
    private let deferred: Deferred<Element>
    
    // MARK:- Public properties

    /// Value of Future
    public private(set) var value: Element? {
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
    
    internal init(deferred: Deferred<Element>) {
        self.deferred = deferred
    }
    
    public init<F: FutureType where F.Element.Value == T, F.Element.Error == E>(future: F) {
        deferred = future.map { Result(result: $0) }
    }
    
    // MARK:- Class methods

    /**
    
        Returns a new immediately completed `Future<T, E>` with given `value`

        - parameter value: value which Future will have

        - returns: a new Future

    */
    public class func succeed(value: T) -> Future {
        return .completed(.Success(value))
    }


    /**

        Returns a new immediately completed `Future<T, E>` with given `error`

        - parameter error: error which Future will have

        - returns: a new Future
        
    */
    public class func failed(error: E) -> Future {
        return .completed(.Failure(error))
    }
    
    /// Creates a new Future with given Result<T, E>
    public static func completed(x: Element) -> Future {
        return Future(deferred: .completed(x))
    }

    // MARK:- FutureType methods

    /**

        Register a callback which will be called when Future is completed

        - parameter ec: execution context of callback
        - parameter c: callback

        - returns: Returns itself for chaining operations
        
    */
    public func onComplete(ec: ExecutionContextType = SideEffects, _ c: CompleteCallback) -> Future {
        deferred.onComplete(ec, c)
        return self
    }


    /**

        Register a callback which will be called when Future is completed with value

        - parameter ec: execution context of callback
        - parameter c: callback

        - returns: Returns itself for chaining operations
        
    */
    public func onSuccess(ec: ExecutionContextType = SideEffects, _ c: SuccessCallback) -> Future {
        return onComplete(ec) { result in
            if let value = result.value {
                c(value)
            }
        }
    }
    
    /**

        Register a callback which will be called when Future is completed with error

        - parameter ec: execution context of callback
        - parameter c: callback

        - returns: Returns itself for chaining operations
        
    */
    public func onError(ec: ExecutionContextType = SideEffects, _ c: ErrorCallback) -> Future {
        return onComplete(ec) { result in
            if let error = result.error {
                c(error)
            }
        }
    }
    
    // MARK:- Internal methods
    
    internal func setValue<R: ResultType where R.Value == T, R.Error == E>(value: R) {
        self.value = Result(result: value)
    }
    
}
