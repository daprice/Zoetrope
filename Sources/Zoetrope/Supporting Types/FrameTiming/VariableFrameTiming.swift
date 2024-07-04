//
//  VariableFrameTiming.swift
//
//
//  Created by Dale Price on 6/30/24.
//

import SwiftUI

/// Defines frames to be played back at a variable frame rate by defining the length of time that each individual frame should be shown for.
///
/// You can also use ``FrameTiming/variable(frameDelays:)`` to construct an instance of this type.
public struct VariableFrameTiming: FrameTiming {
	/// A set of elapsed times after which the next frame should be shown.
	public let frameOffsets: [TimeInterval]
	/// The total duration of one loop of the animation.
	public let duration: TimeInterval
	
	/// The total number of frames in the animation.
	public var frameCount: Int {
		frameOffsets.count
	}
	
	/// Gets the frame index that should be shown after the given amount of time has elapsed during the animation.
	///
	/// Rounds to the nearest millisecond to avoid getting the wrong frame due to floating point inaccuracy.
	public func frameIndex(at elapsedTime: TimeInterval) -> Int {
		guard duration > 0 else { return 0 }
		let elapsedMilliseconds = Int( (elapsedTime * 1000).rounded() )
		let durationMilliseconds = Int( (duration * 1000).rounded() )
		let elapsedWithinLoop = Double((elapsedMilliseconds % durationMilliseconds)) / 1000
		return elapsedWithinLoop >= duration ? 0 : frameOffsets.lastIndex(where: { $0 <= elapsedWithinLoop }) ?? 0
	}
	
	/// Create a TimelineSchedule for updating the view at the start of each frame.
	public func timelineSchedule(paused: Bool, loopStart: Date) -> some TimelineSchedule {
		return VariableFrameTimelineSchedule(timing: self, paused: paused, start: loopStart)
	}
	
	/// Create a schedule for frames to be back with a unique duration for each frame.
	/// - Parameter frameDelays: An array of lengths of time that each frame should be displayed for.
	public init(frameDelays: [TimeInterval]) {
		var duration: TimeInterval = 0
		var frameOffsets: [TimeInterval] = []
		frameOffsets.reserveCapacity(frameDelays.count)
		var frameTime: TimeInterval = 0
		
		for frameDelay in frameDelays {
			duration += frameDelay
			frameOffsets.append((frameTime * 1000).rounded() / 1000)
			frameTime += frameDelay
		}
		
		self.duration = (duration * 1000).rounded() / 1000
		self.frameOffsets = frameOffsets
	}
}

public extension FrameTiming where Self == VariableFrameTiming {
	/// Create a schedule for frames to be back with a unique duration for each frame.
	/// - Parameter frameDelays: An array of lengths of time that each frame should be displayed for.
	/// - Returns: A ``VariableFrameTiming`` instance initialized with frame offsets defined according to the given frame delays.
	static func variable(frameDelays: [TimeInterval]) -> VariableFrameTiming {
		return VariableFrameTiming(frameDelays: frameDelays)
	}
}

extension VariableFrameTiming {
	/// A TimelineSchedule type that defines view updates at the points in time where a new frame should be shown according to a ``VariableFrameTiming`` instance.
	public struct VariableFrameTimelineSchedule: TimelineSchedule {
		public var timing: VariableFrameTiming
		public var paused: Bool
		public var start: Date
		
		public init(timing: VariableFrameTiming, paused: Bool = false, start: Date) {
			self.timing = timing
			self.paused = paused
			self.start = start
		}
		
		public func entries(from startDate: Date, mode: Mode) -> Entries {
			Entries(startDate: startDate, frameTiming: timing, schedule: self, paused: paused || mode == .lowFrequency)
		}
		
		public struct Entries: Sequence {
			private let startDate: Date
			private let sequenceStartDate: Date
			private let frameTiming: VariableFrameTiming
			private var paused: Bool
			
			internal init(startDate: Date, frameTiming: VariableFrameTiming, schedule: VariableFrameTimelineSchedule, paused: Bool) {
				self.frameTiming = frameTiming
				self.paused = paused
				self.startDate = schedule.start
				self.sequenceStartDate = startDate
			}
			
			public func makeIterator() -> EntriesIterator {
				return EntriesIterator(sequenceStartDate: sequenceStartDate, entries: self)
			}
			
			public struct EntriesIterator: IteratorProtocol {
				private let entries: Entries
				private var frame: Int
				
				internal init(sequenceStartDate: Date, entries: Entries) {
					self.entries = entries
					
					let totalElapsed = sequenceStartDate.timeIntervalSince(entries.startDate)
					let loopCount = Int(totalElapsed / entries.frameTiming.duration)
					let currentFrameIndex = entries.frameTiming.frameIndex(at: totalElapsed)
					self.frame = loopCount * entries.frameTiming.frameCount + currentFrameIndex - 1
				}
				
				mutating public func next() -> Date? {
					guard !entries.paused else { return nil }
					
					frame += 1
					
					let loopCount = Int(Double(frame) / Double(entries.frameTiming.frameCount))
					let frameIndex = frame % entries.frameTiming.frameCount
					
					let nextFrameOffset = entries.frameTiming.frameOffsets[Int(frameIndex)]
					return entries.startDate.addingTimeInterval(Double(loopCount) * entries.frameTiming.duration + nextFrameOffset)
				}
			}
		}
	}
}
