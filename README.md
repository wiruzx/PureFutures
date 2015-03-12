#PureFutures

A simple Swift library for Futures and Promises

Highly inspired by [Scala's](http://docs.scala-lang.org/overviews/core/futures.html) implementation.

The main changes from Scala's implementation:

- There is `Deferred<T>` type for computations, that cannot fail
- `PurePromise` it's like `Promise` but for `Deferred`
- `Future<T, E>` and `Promise<T, E>` are also parametrize for Error type

##Examples

To create `Future`:

```swift
let x: Future<Int, NSError> = future(10)
```

or

```swift
let x: Future<Int, NSError> = future {
    sleep(2) // some heavy work
    return 10
}
```

Another way to create `Future` is to use `Promise`:

```swift
let promise = Promise<Int, NSError>() 

dispatch_async(dispatch_get_global_queue(0, 0)) {
    sleep(2)
    promise.success(10)
}

let x: Future<Int, NSError> = promise.future // succeed promise with value `10`
```

or 

```swift
let promise = Promise<Int, NSError>() 

dispatch_async(dispatch_get_global_queue(0, 0)) {
    sleep(2)
    promise.error(NSError())
}

let x: Future<Int, NSError> = promise.future // failed promise
```


Then, you could modify it via `map`:

```swift
let a: Future<Int, NSError> = x.map { $0 * 2 }
```

or `flatMap`:

```swift
let b: Future<Int, NSError> = x.flatMap { someFunctionThatReturnsFuture($0) }
```

Zip two futures together:

```swift
let c: Future<(Int, Int), NSError> = a.zip(b)
```

etc.



To get result from `Future` use `onComplete`, `onSuccess` and `onError`:

```swift

let p = Promise<Int, NSError>()

p.success(10) // or p.error(NSError())

let x = p.future

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


##Instalation

// TODO

##Execution Context


