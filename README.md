#PureFutures

A simple Swift library for Futures and Promises.

Provides convenient way to manage asynchronous code.

Highly inspired by [Scala's](http://docs.scala-lang.org/overviews/core/futures.html) implementation.

The main changes from Scala's implementation:

- There is `Deferred<T>` type for computations, that cannot fail
- For `Deferred` there is `PurePromise`
- `Future<T, E>` and `Promise<T, E>` are also parametrize for Error type

##Basic concepts

###Deferred

`Deferred<T>` represents value that will be available in the future

###PurePromise

`PurePromise<T>` is an object which can complete its `deferred` with a value. Can be completed only once.

###Future

`Future<T, E>` represents computations, that can fail. A convenient way to use `Deferred<Result<T, E>>`

###Promise

`Promise<T, E>` is an object which can complete its `future` with a value or with error. Can be completed only once.

##How to use

To create `Future` we can use `future` function:

```swift
let x: Future<Int, NSError> = future(10)
```

and

```swift
let x: Future<Int, NSError> = future {
    sleep(2) // some heavy work
    return 10
}
```

Or use `Promise` for it:

```swift
let promise = Promise<Int, NSError>() 

dispatch_async(dispatch_get_global_queue(0, 0)) {
    sleep(2)

    // Promise can be completed with success value
    promise.success(10)

    // or error value
    promise.error(NSError())

    // or can be completed with Result<T, E> value
    promise.complete(Result(10))
}

let x: Future<Int, NSError> = promise.future 

```

To get result from `Future` use `onComplete`, `onSuccess` and `onError`:

```swift

// Will be called if future succeed
x.onSuccess { (value: Int) in
    println("value is \(value)")
}

// Will be called if future fails
x.onError { (error: NSError) in
    println("an error occured: \(error)")
}

// Will be called in both cases
x.onComplete { (result: Result<Int, NSError>) in
    switch result {
    case .Success(let box):
        println("value is \(box.value)")
    case .Error(let box):
        println("an error occured: \(box.value)")
    }
}

```

##Examples

Imagine that you have to load list of friends from some social media API

How might it looks without Futures:

```swift
APIManager.login(username: username, password: password, success: { briefUserInfo in
    APIManager.user(forID: briefUserInfo.userID, success: { user in
        APIManager.friends(forUser: user, success: { friends in
            // Do something with friends of user
        }, failure: { error in
            handleError(error)
        })
    }, failure: { error in 
        handleError(error)
    })
}, failure: { error in 
    handleError(error)
}) 
```

And now, how it would look if `APIManager`'s methods returned `Future`s

```swift
APIManager.login(username: username, password: password).flatMap { briefUserInfo in
    APIManager.user(forID: briefUserInfo.userID)
}.flatMap { user in
    APIManager.friends(forUser: user)
}.onSuccess { friends in
    // Do something with friends
}.onError { error in
    handleError(error) // Handle errors in one place
}
```

##Instalation

// TODO

##Execution Context


