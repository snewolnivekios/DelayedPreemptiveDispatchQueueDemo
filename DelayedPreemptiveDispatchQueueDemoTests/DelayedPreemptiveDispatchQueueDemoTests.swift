//
//  DelayedPreemptiveDispatchQueueDemoTests.swift
//  DelayedPreemptiveDispatchQueueDemoTests
//
//  Created by Kevin Owens on 8/15/16.
//  Copyright © 2016 Kevin L. Owens. All rights reserved.
//

import XCTest
@testable import DelayedPreemptiveDispatchQueueDemo

class DelayedPreemptiveDispatchQueueTests: XCTestCase {


  /// Validates a timer-dispatched closure can be preempted by a follow-on timer-dispatched closure with the same identifier.
  func testDelay_Simple() {

    var token: String?
    let dispatchId = "\(#function)"
    let dispatch = DelayedPreemptiveDispatchQueue(label: dispatchId)
    let delayedExpectation = expectation(description: dispatchId)

    dispatch.delay(0.2) {
      token = "hello"
      delayedExpectation.fulfill()
    }
    dispatch.delay(0.25) {
      token = "goodbye"
      delayedExpectation.fulfill()
    }
    dispatch.delay(0.1) {
      token = "hello again"
      delayedExpectation.fulfill()
    }

    waitForExpectations(timeout: 2.0, handler: nil)

    XCTAssertEqual(token, "hello again")
  }


  /// Validates a timer-dispatched closure can be cancelled.
  func testDelay_Preemption_Cancel() {

    let dispatch = DelayedPreemptiveDispatchQueue(label: "testDelay")
    var flag = false

    // Raise flag after a delay
    dispatch.delay(0.2) {
      flag = true
    }

    // "Cancel" the delayed flag-raising
    dispatch.delay(0.1) {
      flag = true
    }

    // Elapse some time
    let delayedExpectation = expectation(description: "testDelay")
    dispatch.delay(0.15) {
      delayedExpectation.fulfill()
    }
    waitForExpectations(timeout: 0.4, handler: nil)

    // Assert flag was not raised (first delay was cancelled)
    XCTAssertFalse(flag)
  }


  /// Validates delay(_:preemptionId:closure:) is thread safe in an otherwise race-condition-rich environment.
  func testDelay_Preemption_RaceCondition() {

    var state = 0
    var finalState = 0

    let dispatchId = "\(#function)"
    var delayedExpectation = expectation(description: dispatchId)
    let dispatch = DelayedPreemptiveDispatchQueue(label: dispatchId) {
      finalState = state
      delayedExpectation.fulfill() // throws exception if called more than once
    }

    let upperBound = 8000
    for i in 0 ..< upperBound {
      state = i
      let withinTwoSeconds: TimeInterval = Double(arc4random()).truncatingRemainder(dividingBy: 100) / 100 * 2
      dispatch.delay(withinTwoSeconds)
    }

    waitForExpectations(timeout: 10, handler: nil)

    // If no race conditions, delay counter will properly increment to some value up to upper bound and decrement to 0; if race conditions exist, it won't decrement to 0.
    XCTAssertEqual(finalState, upperBound - 1)

    //////
    // Validate able to reuse same class

    finalState = 0
    delayedExpectation = expectation(description: dispatchId)
    for i in 0 ..< upperBound {
      state = i
      let seconds: TimeInterval = Double(arc4random()).truncatingRemainder(dividingBy: 100) / 100
      dispatch.delay(seconds)
    }

    waitForExpectations(timeout: 10, handler: nil)
    XCTAssertEqual(finalState, upperBound - 1)
  }
  
}
