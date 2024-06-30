//
//  FrameTiming.swift
//
//
//  Created by Dale Price on 6/30/24.
//

import SwiftUI

public protocol FrameTiming: Equatable, Hashable {
	associatedtype FrameTimelineSchedule: TimelineSchedule
	var duration: TimeInterval { get }
	var frameCount: Int { get }
	func frameIndex(at elapsedTime: TimeInterval) -> Int
	func timelineSchedule(paused: Bool) -> FrameTimelineSchedule
}

public struct ConstantFrameTiming: FrameTiming {
	public var frameCount: Int
	public var duration: TimeInterval
	
	public var frameDuration: TimeInterval? {
		guard duration > 0 && frameCount > 1 else {
			return nil
		}
		
		return duration / Double(frameCount)
	}
	
	public func frameIndex(at elapsedTime: TimeInterval) -> Int {
		guard let frameDuration, duration > 0 else { return 0 }
		let elapsedWithinLoop = elapsedTime.truncatingRemainder(dividingBy: duration)
		return Int(elapsedWithinLoop / frameDuration)
	}
	
	public func timelineSchedule(paused: Bool) -> AnimationTimelineSchedule {
		return AnimationTimelineSchedule(minimumInterval: frameDuration, paused: paused)
	}
	
	public init(frameCount: Int, duration: TimeInterval) {
		self.frameCount = frameCount
		self.duration = duration
	}
}

public extension FrameTiming where Self == ConstantFrameTiming {
	static func constant(frameCount: Int, duration: TimeInterval) -> ConstantFrameTiming {
		return ConstantFrameTiming(frameCount: frameCount, duration: duration)
	}
}

public struct VariableFrameTiming: FrameTiming {
	public let frameOffsets: [TimeInterval]
	public let duration: TimeInterval
	public let startDate: Date
	
	public var frameCount: Int {
		frameOffsets.count
	}
	
	public func frameIndex(at elapsedTime: TimeInterval) -> Int {
		guard duration > 0 else { return 0 }
		let elapsedWithinLoop = elapsedTime.truncatingRemainder(dividingBy: duration)
		return frameOffsets.firstIndex(where: { $0 <= elapsedWithinLoop }) ?? 0
	}
	
	public func timelineSchedule(paused: Bool) -> some TimelineSchedule {
		return VariableFrameTimelineSchedule(timing: self, paused: paused)
	}
	
	public init(frameDelays: [TimeInterval], from startDate: Date) {
		var duration: TimeInterval = 0
		var frameOffsets: [TimeInterval] = []
		frameOffsets.reserveCapacity(frameDelays.count)
		var frameTime: TimeInterval = 0
		
		for frameDelay in frameDelays {
			duration += frameDelay
			frameOffsets.append(frameTime)
			frameTime += frameDelay
		}
		
		self.duration = duration
		self.frameOffsets = frameOffsets
		self.startDate = startDate
	}
}

extension VariableFrameTiming {
	public struct VariableFrameTimelineSchedule: TimelineSchedule {
		public var timing: VariableFrameTiming
		public var paused: Bool
		
		public init(timing: VariableFrameTiming, paused: Bool = false) {
			self.timing = timing
			self.paused = paused
		}
		
		public func entries(from startDate: Date, mode: Mode) -> Entries {
			Entries(startDate: startDate, frameTiming: timing, paused: paused || mode == .lowFrequency)
		}
		
		public struct Entries: Sequence, IteratorProtocol {
			private let startDate: Date
			private let frameTiming: VariableFrameTiming
			private var elapsedSinceAnimationStart: TimeInterval
			private var paused: Bool
			
			internal init(startDate: Date, frameTiming: VariableFrameTiming, paused: Bool) {
				self.startDate = startDate
				self.frameTiming = frameTiming
				self.elapsedSinceAnimationStart = startDate.timeIntervalSince(frameTiming.startDate)
				self.paused = paused
			}
			
			mutating public func next() -> Date? {
				guard !self.paused else { return nil }
				
				let currentFrameIndex = frameTiming.frameIndex(at: elapsedSinceAnimationStart)
				
				let nextFrameIndex = currentFrameIndex + 1 >= frameTiming.frameOffsets.count ? 0 : currentFrameIndex + 1
				let nextFrameOffset = nextFrameIndex == 0 ? frameTiming.duration : frameTiming.frameOffsets[nextFrameIndex]
				
				let loopsCompleted = Int(elapsedSinceAnimationStart / frameTiming.duration)
				let thisLoopStartElapsedTime = Double(loopsCompleted) * frameTiming.duration
				
				let nextFrameElapsedTime = thisLoopStartElapsedTime + nextFrameOffset
				let timeUntilNextFrame = nextFrameElapsedTime - elapsedSinceAnimationStart
				defer { elapsedSinceAnimationStart += timeUntilNextFrame }
				return frameTiming.startDate.addingTimeInterval(nextFrameElapsedTime)
			}
		}
	}
}
