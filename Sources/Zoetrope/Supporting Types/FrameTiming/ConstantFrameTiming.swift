//
//  ConstantFrameTiming.swift
//
//
//  Created by Dale Price on 6/30/24.
//

import SwiftUI

/// Defines frames to be played back at a constant frame rate.
///
/// You can also use ``FrameTiming/constant(frameCount:duration:)`` to construct an instance of this type.
public struct ConstantFrameTiming: FrameTiming {
	/// The number of frames in the animation.
	public var frameCount: Int
	/// The total duration of one loop of the animation.
	public var duration: TimeInterval
	
	/// The length of time that each frame should be shown for.
	public var frameDuration: TimeInterval? {
		guard duration > 0 && frameCount > 1 else {
			return nil
		}
		
		return duration / Double(frameCount)
	}
	
	/// Gets the frame index that should be shown after the given amount of time has elapsed during the animation.
	public func frameIndex(at elapsedTime: TimeInterval) -> Int {
		guard let frameDuration, duration > 0 else { return 0 }
		let elapsedWithinLoop = elapsedTime.truncatingRemainder(dividingBy: duration)
		return Int(elapsedWithinLoop / frameDuration)
	}
	
	/// Create a TimelineSchedule for updating the view at the necessary interval.
	public func timelineSchedule(paused: Bool, loopStart _: Date) -> AnimationTimelineSchedule {
		return AnimationTimelineSchedule(minimumInterval: frameDuration, paused: paused)
	}
	
	/// Create a schedule for frames to be played back at a constant frame rate.
	/// - Parameters:
	///   - frameCount: The number of frames in the animation.
	///   - duration: The total duration of one loop of the animation.
	public init(frameCount: Int, duration: TimeInterval) {
		self.frameCount = frameCount
		self.duration = duration
	}
}

public extension FrameTiming where Self == ConstantFrameTiming {
	/// Create a schedule for frames to be played back at a constant frame rate.
	/// - Parameters:
	///   - frameCount: The number of frames in the animation.
	///   - duration: The total duration of one loop of the animation.
	/// - Returns: A ``ConstantFrameTiming`` instance constructed using the given parameters.
	static func constant(frameCount: Int, duration: TimeInterval) -> ConstantFrameTiming {
		return ConstantFrameTiming(frameCount: frameCount, duration: duration)
	}
}

