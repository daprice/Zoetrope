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
