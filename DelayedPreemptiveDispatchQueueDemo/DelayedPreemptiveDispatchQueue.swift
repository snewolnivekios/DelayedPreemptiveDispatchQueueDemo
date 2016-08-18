//
//  DelayedPreemptiveDispatchQueue.swift
//  DelayedPreemptiveDispatchQueueDemo
//
//  Copyright © 2016 Kevin L. Owens. All rights reserved.
//
//  DelayedPreemptiveDispatchQueueDemo is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  DelayedPreemptiveDispatchQueueDemo is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with DelayedPreemptiveDispatchQueueDemo.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation


/// With a delayed preemptive dispatch queue, you can delay execution of some task for a period of time, then later extend that time or preempt execution of the task, either by replacing it with some other task or by canceling it altogether.
///
/// The task may be provided via `init(label:task:)`, `delay(_:task:)`, or a combination of both. Neither the delay times nor tasks need be the same with each call. Only the last task submitted will be called once _all_ concurrent delay timers have expired. While you cannot cancel the timers, you can cancel execution of the associated task via `cancel()`. Once all timers have expired, you can reuse the `DelayedPreemptiveDispatchQueue` with or without specifying a new task.
///
/// While this class makes use of the `DispatchGroup` to manage a group of timers, this same functionality is not inherent to it. For example, you cannot provide a task closure to a `DispatchGroup` at initilization, but only via its instance `notify()` method. Also, all closures submitted to a dispatch group execute; there is no "preemption".
class DelayedPreemptiveDispatchQueue {

  /// The custom dispatch queue used to manage the delayed dispatch of the tasks.
  private let queue: DispatchQueue

  /// The task to perform once all delays in a group have expired. Provided via `init(label:task:)` and `delay(_:task:)`.
  private var task: (() -> Void)!

  /// Used to manage the delayed dispatch of the `notify` closure.
  private var group = DispatchGroup()

  /// On the first call to `delay(_:)` for a group of delays, this value is set to and remains `false` until the final delay expires, at which time it returns to `true`.
  private(set) var empty = true

  /// Indicates pending task has been cancelled via a call to `cancel()`.
  private var cancelled = false


  /// Prepares the queue for managing delay timers and stashes the `task` to be executed once the timers have expired.
  ///
  /// - parameter label: Identifier for a custom dispatch queue. If `nil` (the default), a class-specific identifier is used.
  /// - parameter task: The closure to execute once all pending delays have expired. Optionally, you may defer providing this `task` until the call to `delay(_:task:)`. Defaults to `nil`.
  init(label: String? = nil, task: (() -> Void)? = nil) {
    queue = DispatchQueue(label: label ?? "\(#file)", attributes: DispatchQueue.Attributes.concurrent)
    self.task = task
  }


  /// Executes `task` no earlier than after the given delay.
  ///
  /// Subsequent calls to this method will preempt execution of this `task`. The task may also be provided via the class initializer. Cancel execution of a task via `cancel()`.
  ///
  /// - parameter seconds: The number of seconds before this or the initializer-givn task may be executed. The delay will be longer if there is a pending delay that expires after this period.
  /// - parameter task: The closure to run after _all_ pending delays have expired. If `nil` (the default), the task to be run is that given at initialization. If no task was given during initialization or at any call to this method, it takes no action.
  func delay(_ seconds: TimeInterval, task: (() -> Void)? = nil) {

    // Make sure we have a defined task task
    if task != nil {
      self.task = task
    }
    guard self.task != nil else { return }

    // Newly submitted task preempts prior cancellation
    cancelled = false

    // Add delay timer to the dispatch group
    group.enter()
    self.queue.asyncAfter(deadline: DispatchTime.now() + seconds) {
      self.group.leave()
    }

    // Only assign GCD notify action when first timer added to group.
    // The notify action, which performs the task, runs once all timers have left the group.
    if empty {
      self.empty = false
      group.notify(queue: .main) {
        if !self.cancelled {
          self.task()
        }
        self.empty = true
      }
    }
  }


  /// Causes the cancelation of any pending task.
  ///
  /// The dispatch queue is immediately available for reuse. Any subsequent call to `delay(_:task:)` will use the last-submitted task, whether via that function or the class initializer. 
  ///
  /// To use a different task, either create a new `DelayedPreemptiveDispatchQueue` or pass one to `delay(_:task:)`.
  func cancel() {
    cancelled = true
  }
}
