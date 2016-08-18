//
//  ViewController.swift
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

/// Manages the delayed preemptive dispatch queue demo view.
class ViewController: UIViewController {

  
  // MARK: - Delay Duration

  /// Control for changing the duration of the delay timer.
  @IBOutlet weak var delayDurationSlider: UISlider!

  /// Shows the value selected via the `delayDurationSlider`.
  @IBOutlet weak var delayDurationLabel: UILabel!

  /// The user-selected duration of the delay timer.
  /// Updates `delayDurationLabel` on set.
  var delayDuration: TimeInterval! {
    didSet {
      self.delayDurationLabel.text = "\(Int(delayDuration))s"
    }
  }


  // MARK: - Delay Timer

  /// Visualizes the delay timer.
  @IBOutlet weak var timerProgressView: UIProgressView!

  /// The timer interface used to start, stop, and cancel a delay timer as visualized by the `timerProgressView`.
  var progressViewTimer: ProgressViewTimer!


  // MARK: - Task Identifier

  /// A task identifier that distinguishes one task from another. Displayed in the `taskLabel`.
  var taskId = 0

  /// Identifies the task last submitted on the `taskDispatchQueue`.
  @IBOutlet weak var taskLabel: UILabel!


  // MARK: - Task Dispatch Queue

  /// The dispatch queue to which tasks are added, the last being that executed.
  var taskDispatchQueue: DelayedPreemptiveDispatchQueue!

  /// True when tasks are pending on the `taskDispatchQueue`. Determines the action taken by `cancelTask(_:)`.
  var tasksPending = false


  // MARK: - View Initialization

  /// Initializes the delayed dispatch queue and hooks into progress timer value-changed events.
  override func viewDidLoad() {
    super.viewDidLoad()

    // Setup dispatch queue to run the task and reset the timer
    taskDispatchQueue = DelayedPreemptiveDispatchQueue() {
      self.taskLabel.text = "Executed task #\(self.taskId)"
      self.progressViewTimer.finish()
      self.tasksPending = false
    }

    // Get initial timer duration from slider and register self as value-changed listener
    delayDuration = TimeInterval(delayDurationSlider.value)
    delayDurationSlider.addTarget(self, action: #selector(ViewController.sliderValueChanged), for: .valueChanged)
  }


  // MARK: - User Actions


  /// At the user's request, submits a task onto the dispatch queue, that if not replaced with a subsequent task or cancelled, will run after the `timerDuration` period.
  @IBAction func submitTask(_ sender: UIButton) {

    taskId += 1
    taskLabel.text = "Submitted task #\(taskId)"
    taskDispatchQueue.delay(delayDuration)

    progressViewTimer?.stop()
    progressViewTimer = ProgressViewTimer(progressView: timerProgressView, forDuration: delayDuration)
    progressViewTimer.start()
    tasksPending = true
  }


  /// Cancels any pending task, or if no tasks pending, resets the task and timer views.
  @IBAction func cancelTask(_ sender: UIButton) {
    if tasksPending {
      taskLabel.text = "Cancelled task #\(self.taskId)"
      taskDispatchQueue.cancel()
      progressViewTimer.stop()
      tasksPending = false
    } else {
      taskLabel.text = " "
      timerProgressView.progress = 0
    }
  }

  /// Updates `timerDuration` in response to `delayDurationSlider` value change, rounding the value to the nearest whole number.
  func sliderValueChanged() {
    delayDuration = round(Double(delayDurationSlider.value))
  }
}
