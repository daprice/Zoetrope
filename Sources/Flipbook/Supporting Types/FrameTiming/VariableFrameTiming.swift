//
//  VariableFrameTiming.swift
//
//
//  Created by Dale Price on 6/30/24.
//

import SwiftUI

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
//		return frameOffsets.lastIndex(where: { $0 <= elapsedWithinLoop }) ?? 0
		return closestFrameIndex(toOffset: elapsedWithinLoop) ?? 0
	}
	
	private func closestFrameIndex(toOffset offset: TimeInterval) -> Int? {
		return frameOffsets.enumerated().min { lhs, rhs in
			return abs(offset - lhs.element) < abs(offset - rhs.element)
		}?.offset ?? 0
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

public extension FrameTiming where Self == VariableFrameTiming {
	static func variable(frameDelays: [TimeInterval], from startDate: Date = Date(timeIntervalSince1970: 0)) -> VariableFrameTiming {
		return VariableFrameTiming(frameDelays: frameDelays, from: startDate)
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
			private var paused: Bool
			
			private var loopStartDate: Date
			private var frameIndex: Int
			
			internal init(startDate: Date, frameTiming: VariableFrameTiming, paused: Bool) {
				self.startDate = startDate
				self.frameTiming = frameTiming
				self.paused = paused
				
				let totalElapsed = startDate.timeIntervalSince(frameTiming.startDate)
				let loopsCompleted = Int(totalElapsed / frameTiming.duration)
				let currentFrameIndex = frameTiming.frameIndex(at: totalElapsed)
				self.loopStartDate = Date(timeInterval: Double(loopsCompleted) * frameTiming.duration, since: frameTiming.startDate)
				self.frameIndex = currentFrameIndex
			}
			
			mutating public func next() -> Date? {
				guard !self.paused else { return nil }
				
				if frameIndex >= frameTiming.frameCount - 1 {
					let nextFrameOffset = frameTiming.duration
					defer {
						loopStartDate = loopStartDate.addingTimeInterval(frameTiming.duration)
						frameIndex = 0
					}
					return loopStartDate.addingTimeInterval(nextFrameOffset)
				} else {
					frameIndex += 1
					return loopStartDate.addingTimeInterval(frameTiming.frameOffsets[frameIndex])
				}
			}
		}
	}
}
