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

    :param: dx Deferred
    :param: f side-effecting function that will be applied to result of `dx`
    :param: ec execution context of `f` function

    :returns: a new Deferred

*/
public func andThen<D: DeferredType>(dx: D, f: D.Element -> Void)(_ ec: ExecutionContextType) -> Deferred<D.Element> {
    let p = PurePromise<D.Element>()
    dx.onComplete(ec) { value in
        f(value)
        p.complete(value)
    }
    return p.deferred
}

/**

    Stops the current thread, until value of `dx` becomes available

    :param: dx Deferred

    :returns: value of deferred

*/
public func forced<D: DeferredType>(dx: D) -> D.Element {
    return forced(dx, NSTimeInterval.infinity)!
}

/**

    Stops the currend thread, and wait for `inverval` seconds until value of `dx` becoms available

    :param: dx Deferred
    :param: inverval number of seconds to wait

    :returns: Value of deferred or nil if it hasn't become available yet

*/
public func forced<D: DeferredType>(dx: D, interval: NSTimeInterval) -> D.Element? {
    return await(interval) { completion in
        dx.onComplete(ExecutionContext.DefaultPureOperationContext, completion)
        return
    }
}

/**

    Creates a new deferred by applying a function `f` to the result of this deferred.

    :param: dx Deferred
    :param: f Function that will be applied to result of `dx`
    :param: ec Execution context of `f`

    :returns: a new Deferred

*/
public func map<D: DeferredType, T>(dx: D, f: D.Element -> T)(_ ec: ExecutionContextType) -> Deferred<T> {
    let p = PurePromise<T>()
    dx.onComplete(ec) { p.complete(f($0)) }
    return p.deferred
}

/**

    Creates a new deferred by applying a function to the result of this deferred, and returns the result of the function as the new deferred.

    :param: dx Deferred
    :param: f Funcion that will be applied to result of `dx`
    :param: ec Execution context of `f`

    :returns: a new Deferred

*/
public func flatMap<D: DeferredType, D2: DeferredType>(dx: D, f: D.Element -> D2)(_ ec: ExecutionContextType) -> Deferred<D2.Element> {
    let p = PurePromise<D2.Element>()
    dx.onComplete(ec) { p.completeWith(f($0)) }
    return p.deferred
}

/**

    Converts Deferred<Deferred<T>> into Deferred<T>

    :param: dx Deferred

    :returns: flattened Deferred

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

    :param: dx Deferred
    :param: p Predicate function
    :param: ec Execution context of `p`

    :returns: A new Deferred with value or nil

*/
public func filter<D: DeferredType>(dx: D, p: D.Element -> Bool)(_ ec: ExecutionContextType) -> Deferred<D.Element?> {
    return map(dx) { x in p(x) ? x : nil }(ec)
}

/**

    Zips two deferred together and returns a new Deferred which contains a tuple of two elements

    :param: da First deferred
    :param: db Second deferred

    :returns: Deferred with resuls of two deferreds

*/
public func zip<DA: DeferredType, DB: DeferredType>(da: DA, db: DB) -> Deferred<(DA.Element, DB.Element)> {
    
    let ec = ExecutionContext.DefaultPureOperationContext
    
    return flatMap(da) { a in
        map(db) { b in
            (a, b)
        }(ec)
    }(ec)
}

/**

    Reduces the elements of sequence of deferreds using the specified reducing function `combine`

    :param: dxs Sequence of Deferred
    :param: initial Initial value that will be passed as first argument in `combine` function
    :param: combine reducing function
    :param: ec Execution context of `combine`

    :returns: Deferred which will contain result of reducing sequence of deferreds

*/
public func reduce<S: SequenceType, T where S.Generator.Element: DeferredType>(dxs: S, initial: T, combine: (T, S.Generator.Element.Element) -> T)(_ ec: ExecutionContextType) -> Deferred<T> {
    return reduce(dxs, Deferred(initial)) { acc, defValue in
        flatMap(defValue) { value in
            map(acc) { combine($0, value) }(ec)
        }(ec)
    }
}

/**

    Transforms a sequence of values into Deferred of array of this values using the provided function `f`

    :param: xs Sequence of values
    :param: f Function for transformation values into Deferred
    :param: ec Execution context of `f`

    :returns: a new Deferred

*/
public func traverse<S: SequenceType, D: DeferredType>(xs: S, f: S.Generator.Element -> D)(_ ec: ExecutionContextType) -> Deferred<[D.Element]> {
    return reduce(map(xs, f), []) { $0 + [$1] }(ec)
}

/**

    Transforms a sequnce of Deferreds into Deferred of array of values:

    [Deferred<T>] -> Deferred<[T]>

    :param: dxs Sequence of Deferreds

    :returns: Deferred with array of values

*/
public func sequence<S: SequenceType where S.Generator.Element: DeferredType>(dxs: S) -> Deferred<[S.Generator.Element.Element]> {
    return traverse(dxs, id)(ExecutionContext.DefaultPureOperationContext)
}

/**

    Transforms Deferred into Future

    :param: dx Deferred

    :returns: a new Future with result of Deferred

*/
public func toFuture<D: DeferredType, T, E where D.Element == Result<T, E>>(dx: D) -> Future<T, E> {
    let p = Promise<T, E>()
    
    dx.onComplete(ExecutionContext.DefaultPureOperationContext) {
        p.complete($0)
    }
    
    return p.future
}
