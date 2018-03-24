//
//  Promise.swift
//  PureFutures
//
//  Created by Victor Shamanov on 2/11/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

public final class Promise<T> {

    public enum Error: Swift.Error {
        case alreadyCompleted
    }

    public let future = Future<T>()

    public init() {}

    public func complete(result: Result<T>) throws {
        guard !future.isCompleted else { throw Error.alreadyCompleted }
        future.set(value: result)
    }

    // Convenience

    public func complete(future: Future<T>) {
        future.onComplete {
            try? self.complete(result: $0)
        }
    }

    public func complete(success: T) throws {
        try complete(result: .success(success))
    }

    public func complete(failure: Error) throws {
        try complete(result: .failure(failure))
    }
}
