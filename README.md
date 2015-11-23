#PureFutures

[![Build Status](https://travis-ci.org/wiruzx/PureFutures.svg?branch=master)](https://travis-ci.org/wiruzx/PureFutures) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

A simple Futures and Promises library.

Highly inspired by [Scala's implementation](http://docs.scala-lang.org/overviews/core/futures.html)

##Instalation

###Carthage

Add the following in your Cartfile:

```
github "wiruzx/PureFutures"
```

And run `carthage update`

Up to date instructions in [Carthage's README](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

###Git submodules

* Add PureFutures submodule into your project `git submodule add https://github.com/wiruzx/PureFutures.git`
* Drag `PureFutures.xcodeproj` file into your project
* Add PureFutures as target dependency in **Build Phases** section
* Add `PureFutures.framework` to **Link Binary With Libraries** section

##Alternatives:

1. [BrightFutures](https://github.com/Thomvis/BrightFutures) ❤️
2. [PromiseKit](https://github.com/mxcl/PromiseKit) 👍
3. [Bolts](https://github.com/BoltsFramework/Bolts-iOS) 😏
4. [SwiftTask](https://github.com/ReactKit/SwiftTask) 😐

##License

PureFutures is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
