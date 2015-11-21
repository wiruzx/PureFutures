//
//  DeferredTypeFunctions.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/24/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import typealias Foundation.NSTimeInterval

/**

    Applies the side-effecting function to the result of this deferred,
    and returns a new deferred with the result of this deferred

    - parameter f: side-effecting function that will be applied to result of `dx`
    - parameter ec: execution context of `f` function. By default is main queue
    - parameter dx: Deferred

    - returns: a new Deferred

*/
public func andThen<D: DeferredType>(f: (D.Element -> Void), _ ec: ExecutionContextType = ExecutionContext.DefaultSideEffectsContext)(_ dx: D) -> Deferred<D.Element> {
    let p = PurePromise<D.Element>()
    dx.onComplete(ec) { value in
        f(value)
        p.complete(value)
    }
    return p.deferred
}

/**

    Stops the current thread, until value of `dx` becomes available

    - parameter dx: Deferred

    - returns: value of deferred

*/
public func forced<D: DeferredType>(dx: D) -> D.Element {
    return forced(NSTimeInterval.infinity)(dx)!
}

/**

    Stops the currend thread, and wait for `inverval` seconds until value of `dx` becoms available

    - parameter inverval: number of seconds to wait

    - parameter dx: Deferred

    - returns: Value of deferred or nil if it hasn't become available yet

*/
public func forced<D: DeferredType>(interval: NSTimeInterval)(_ dx: D) -> D.Element? {
    return await(interval) { completion in
        dx.onComplete(ExecutionContext.DefaultPureOperationContext, completion)
        return
    }
}

/**

    Creates a new deferred by applying a function `f` to the result of this deferred.

    - parameter f: Function that will be applied to result of `dx`
    - parameter ec: Execution context of `f`. By defalut is global queue

    - parameter dx: Deferred

    - returns: a new Deferred

*/
public func map<D: DeferredType, T>(f: (D.Element -> T), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ dx: D) -> Deferred<T> {
    let p = PurePromise<T>()
    dx.onComplete(ec) { p.complete(f($0)) }
    return p.deferred
}

/**

    Creates a new deferred by applying a function to the result of this deferred, and returns the result of the function as the new deferred.

    - parameter f: Funcion that will be applied to result of `dx`
    - parameter ec: Execution context of `f`. By defalut is global queue

    - parameter dx: Deferred

    - returns: a new Deferred

*/
public func flatMap<D: DeferredType, D2: DeferredType>(f: (D.Element -> D2), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ dx: D) -> Deferred<D2.Element> {
    let p = PurePromise<D2.Element>()
    dx.onComplete(ec) { p.completeWith(f($0)) }
    return p.deferred
}

/**

    Converts Deferred<Deferred<T>> into Deferred<T>

    - parameter dx: Deferred

    - returns: flattened Deferred

*/
public func flatten<D: DeferredType, ID: DeferredType where D.Element == ID>(dx: D) -> Deferred<ID.Element> {
    let p = PurePromise<ID.Element>()
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    dx.onComplete(ec) { def in
        def.onComplete(ec) { p.complete($0) }
    }
    
    return p.deferred
}

/**

    Creates a new Deferred by filtering the value of the current Deferred with a predicate `p`

    - parameter p: Predicate function
    - parameter ec: Execution context of `p`. By defalut is global queue

    - parameter Deferred:

    - returns: A new Deferred with value or nil

*/
public func filter<D: DeferredType>(p: (D.Element -> Bool), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext) -> D -> Deferred<D.Element?> {
    return map({ x in p(x) ? x : nil }, ec)
}

/**

    Zips two deferred together and returns a new Deferred which contains a tuple of two elements

    - parameter da: First deferred

    - parameter db: Second deferred

    - returns: Deferred with resuls of two deferreds

*/
public func zip<DA: DeferredType, DB: DeferredType>(da: DA)(_ db: DB) -> Deferred<(DA.Element, DB.Element)> {
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    return flatMap({ a in
        map({ b in
            (a, b)
        }, ec)(db)
    }, ec)(da)
}

/**

    Reduces the elements of sequence of deferreds using the specified reducing function `combine`

    - parameter combine: reducing function
    - parameter initial: Initial value that will be passed as first argument in `combine` function
    - parameter ec: Execution context of `combine`. By defalut is global queue

    - parameter dxs: Sequence of Deferred

    - returns: Deferred which will contain result of reducing sequence of deferreds

*/
public func reduce<S: SequenceType, T where S.Generator.Element: DeferredType>(combine: ((T, S.Generator.Element.Element) -> T), _ initial: T, _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ dxs: S) -> Deferred<T> {
    return dxs.reduce(.completed(initial)) { acc, defValue in
        flatMap({ value in
            map({ combine($0, value) }, ec)(acc)
        }, ec)(defValue)
    }
}

/**

    Transforms a sequence of values into Deferred of array of this values using the provided function `f`

    - parameter f: Function for transformation values into Deferred
    - parameter ec: Execution context of `f`. By defalut is global queue

    - parameter xs: Sequence of values

    - returns: a new Deferred

*/
public func traverse<S: SequenceType, D: DeferredType>(f: (S.Generator.Element -> D), _ ec: ExecutionContextType = ExecutionContext.DefaultPureOperationContext)(_ xs: S) -> Deferred<[D.Element]> {
    return reduce({ $0 + [$1] }, [], ec)(xs.map(f))
}

/**

    Transforms a sequnce of Deferreds into Deferred of array of values:

    [Deferred<T>] -> Deferred<[T]>

    - parameter dxs: Sequence of Deferreds

    - returns: Deferred with array of values

*/
public func sequence<S: SequenceType where S.Generator.Element: DeferredType>(dxs: S) -> Deferred<[S.Generator.Element.Element]> {
    return traverse(id, ExecutionContext.DefaultPureOperationContext)(dxs)
}

/**

    Transforms Deferred into Future

    - parameter dx: Deferred

    - returns: a new Future with result of Deferred

*/
public func toFuture<D: DeferredType, T, E: ErrorType where D.Element == Result<T, E>>(dx: D) -> Future<T, E> {
    let p = Promise<T, E>()
    
    dx.onComplete(ExecutionContext.DefaultPureOperationContext) {
        p.complete($0)
    }
    
    return p.future
}
