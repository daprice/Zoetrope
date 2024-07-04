//
//  FrameTiming.swift
//
//
//  Created by Dale Price on 6/30/24.
//

import SwiftUI

/// A type that provides information about when to display frames in a ``FrameAnimator``.
public protocol FrameTiming: Equatable, Hashable {
	/// An alias for the timeline schedule that ``FrameAnimator`` uses to update its view.
	associatedtype FrameTimelineSchedule: TimelineSchedule
	
	/// The total duration of one loop of the animation.
	var duration: TimeInterval { get }
	
	/// The number of frames in the animation.
	var frameCount: Int { get }
	
	/// Returns the index of the frame that should be displayed after a given amount of time has elapsed since the start of the animation.
	func frameIndex(at elapsedTime: TimeInterval) -> Int
	
	/// Provides a timeline schedule for ``FrameAnimator`` to use to update its view.
	func timelineSchedule(paused: Bool, loopStart: Date) -> FrameTimelineSchedule
}
