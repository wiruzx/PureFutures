#PureFutures

A simple Swift library for Futures and Promises.

Provides convenient way to manage asynchronous code.

Highly inspired by [Scala's implementation](http://docs.scala-lang.org/overviews/core/futures.html).
[Main changes](https://github.com/wiruzx/PureFutures/wiki) from Scala's implementation

##Basic concepts

###Deferred

`Deferred<T>` represents value that will be available in the future

###PurePromise

`PurePromise<T>` is an object which can complete its `deferred` with a value. Can be completed only once.

###Future

`Future<T, E>` represents computations, that can fail. A convenient way to use `Deferred<Result<T, E>>`

###Promise

`Promise<T, E>` is an object which can complete its `future` with a value or with error. Can be completed only once.

See [documentation](https://github.com/wiruzx/PureFutures/wiki) for more information.

##Examples

// TODO

##Wrapping existing API

You can easily wrap your existing methods with callbacks into `Future` :

```swift
func userInfo(userID: String) -> Future<User, NSError> {
    let p = Promise<User, NSError>()
    APIManager.getUserInfo(forUserID: userID, success: { user in
        p.success(user)
    }, failure: { error in
        p.error(error)
    })
    return p.future
}
```

For computations, that cannot finish with error, it makes sense to use `Deferred`:

```swift
func encryptedData(fromData data: NSData) -> Deferred<NSData> {
    let p = PurePromise<NSData>()
    encryptData(data) { encryptedData in
        p.complete(encryptedData)
    }
    return p.deferred
}
```

##Execution Context

A lot of `Future`'s and `Deferred`'s methods have `execution context` parameter. It defines context of execution callback.

You can use `dispatch_queue_t` and `NSOperationQueue` as execution context, to execute callbacks on particular queue

To create custom execution context just create type that conforms to `ExecutionContextType` protocol.

For example, the following execution context will execute callbacks with delay on main thread:

```swift

class DelayedExecutionContext: ExecutionContextType {
    let delayInterval: NSTimeInterval

    init(interval: NSTimeInterval) {
        delayInterval = interval
    }
    
    func execute(task: () -> Void) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delayInterval * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            task()
        }
    }
}

```

###Usage: 

```swift

let executionContext = DelayedExecutionContext(interval: 10)

let future: Future<Int, NSError> = future {
    sleep(2)
    return 42
}

future.onSuccess(executionContext) { value in
    println(value) // will be printed 10 seconds later the completion of future. 
}
    
```

##Instalation

* Add PureFutures submodule into your project `git submodule add https://github.com/wiruzx/PureFutures.git`
* Drag `PureFutures.xcodeproj` file into your project
* Add PureFutures as target dependency in **Build Phases** section
* Add `PureFutures.framework` to **Link Binary With Libraries** section
* Import it `import PureFutures` when you're going to use it


##Alternatives:

1. [BrightFutures](https://github.com/Thomvis/BrightFutures) ❤️
2. [PromiseKit](https://github.com/mxcl/PromiseKit) 👍
3. [Bolts](https://github.com/BoltsFramework/Bolts-iOS) 😏
4. [SwiftTask](https://github.com/ReactKit/SwiftTask) 😐

##License

PureFutures is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

