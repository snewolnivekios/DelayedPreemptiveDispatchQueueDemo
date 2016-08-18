//
//  ProgressViewTimer.swift
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

import UIKit

/// Manages a client-provided `UIProgressView` to show elapsed time.
///
/// With this class, you provide the slider and timer duration via the initializer, and control the timer via its `start()`, `stop()`, and `finish()` methods.
class ProgressViewTimer {

  /// The progress view used to represent elapsed time.
  let progressView: UIProgressView

  /// The step by which the slider is incremented.
  let progressStep: Float = 0.01

  /// The duration of the timer.
  let timerDuration: TimeInterval

  /// The delay timer.
  var progressTimer: Timer?


  /// Initializes self to represent a timer in `progressView` for the given `duration`.
  init(progressView: UIProgressView, forDuration duration: TimeInterval) {
    self.progressView = progressView
    timerDuration = duration / Double(1 / progressStep)
  }

  /// Starts (or restarts) the timer.
  func start() {
    progressTimer?.invalidate()
    progressView.progress = 0
    if #available(iOS 10.0, *) {
      progressTimer = Timer.scheduledTimer(withTimeInterval: timerDuration, repeats: true) { _ in
        self.progressView.progress += self.progressStep
      }
    } else {
      // Fallback on earlier versions
      progressTimer = Timer.scheduledTimer(timeInterval: timerDuration, target: self, selector: #selector(ProgressViewTimer.stepProgress), userInfo: nil, repeats: true)
    }
  }

  /// Increments the progress view at the expiration of the timer by `progressStep`.
  @objc func stepProgress(timer: Timer) {
    self.progressView.progress += self.progressStep
  }

  /// Stops the timer, leaving the progress view at its current state.
  func stop() {
    progressTimer?.invalidate()
  }

  /// Stops the timer and updates the progress view to show progress complete.
  func finish() {
    stop()
    progressView.progress = 1
  }
}
