//
//  AwaitTests.swift
//  PureFutures
//
//  Created by Victor Shamanov on 3/3/15.
//  Copyright (c) 2015 Victor Shamanov. All rights reserved.
//

import XCTest

@testable import PureFutures

func someAsyncWork(_ time: UInt32, completion: @escaping () -> Void) {
    DispatchQueue.global().async {
        sleep(time)
        completion()
    }
}

class AwaitTests: XCTestCase {

    func testAwaitWithTime() {
        let result = await(3) { completion in
            someAsyncWork(2) {
                completion(42)
            }
        }
        
        if let result = result {
            XCTAssertEqual(result, 42)
        } else {
            XCTFail("Result is nil")
        }
    }
    
    func testAwaitInifinite() {
        let result = await(TimeInterval.infinity) { completion in
            someAsyncWork(3) {
                completion(42)
            }
        }
        
        if let result = result {
            XCTAssertEqual(result, 42)
        } else {
            XCTFail("Result is nil")
        }
    }
    
    func testAwaitFail() {
        let result = await(2) { completion in
            someAsyncWork(3) {
                completion(42)
            }
        }
        
        XCTAssertNil(result)
    }

}
