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
