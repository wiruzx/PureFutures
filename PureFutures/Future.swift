//
//  Future.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import Foundation

public final class Future<T> {

    private typealias Callback = (Result<T>) -> Void

    private var callbacks: [Callback] = []
    private let queue = DispatchQueue(label: "com.wiruzx.pure-futures.future.queue")

    public private(set) var result: Result<T>?

    public var isCompleted: Bool {
        return result != nil
    }

    internal init() {}

    public convenience init(result: Result<T>) {
        self.init()
        self.result = result
    }

    // Convenience

    public convenience init(value: T) {
        self.init(result: .success(value))
    }

    public convenience init(error: Error) {
        self.init(result: .failure(error))
    }

    @discardableResult
    public func onComplete(completion: @escaping (Result<T>) -> Void) -> Future<T> {
        queue.sync {
            if let result = result {
                completion(result)
            } else {
                callbacks.append(completion)
            }
        }
        return self
    }

    internal func set(value: Result<T>) {
        precondition(!isCompleted)
        queue.sync {
            self.result = value
            for callback in callbacks {
                callback(value)
            }
            callbacks.removeAll()
        }
    }
}
