//
//  FrameAnimator.swift
//
//
//  Created by Dale Price on 6/30/24.
//

import SwiftUI

/// A view that displays frames of an animation according to timings that you provide.
///
/// - Important: FrameAnimator does not automatically do anything to respect the user's accessibility settings. You should take such measures yourself, for example by responding to `accessibilityPlayAnimatedImages`, `accessibilityReduceMotion`, and/or `accessibilityDimFlashingLights` as appropriate for your use case.
public struct FrameAnimator<Timing: FrameTiming, Content: View>: View {
	public var timing: Timing
	public var start: Date
	public var paused: Bool
	public var loops: UInt?
	@ViewBuilder public var content: (_ frame: Int) -> Content
	
	public init(
		_ timing: Timing,
		start: Date = Date(timeIntervalSince1970: 0),
		paused: Bool = false,
		loops: UInt? = nil,
		@ViewBuilder content: @escaping (_ frame: Int) -> Content
	) {
		self.timing = timing
		self.start = start
		self.paused = paused
		self.loops = loops
		self.content = content
	}
	
	private var canAnimate: Bool {
		timing.duration > 0
	}
	
	private func frameIndex(at date: Date) -> Int {
		guard canAnimate else {
			return 0
		}
		let elapsed = date.timeIntervalSince(start)
		
		if hasReachedLoopLimit(at: date) {
			return timing.frameCount - 1
		} else {
			return timing.frameIndex(at: elapsed)
		}
	}
	
	private func hasReachedLoopLimit(at date: Date) -> Bool {
		if let loops {
			let elapsed = date.timeIntervalSince(start)
			return elapsed >= timing.duration * Double(loops)
		} else {
			return false
		}
	}
	
    public var body: some View {
		if canAnimate {
			TimelineView(timing.timelineSchedule(paused: paused || hasReachedLoopLimit(at: .now), loopStart: start)) { context in
				let frame = frameIndex(at: context.date)
				content(frame)
			}
		} else {
			content(0)
		}
    }
}

#Preview {
	FrameAnimator(.constant(frameCount: 10, duration: 2)) { frame in
		Image(systemName: "\(frame).circle.fill")
			.font(.system(size: 100))
	}
}

#Preview {
	FrameAnimator(.variable(frameDelays: [
		0.5,
		1,
		0.5,
		1,
		0.5,
		0.1,
		0.1,
		1,
		0.5,
		1,
		0.5,
		1,
	])) { frame in
		Image(systemName: "\(frame).circle.fill")
			.font(.system(size: 100))
	}
}

#Preview {
	FrameAnimator(.variable(frameDelays: [
		0.1,
		0.2,
		0.1,
		0.2,
		0.1,
		0.2,
		0.1,
		0.2,
		0.1,
		0.2,
		0.1,
		0.2,
		0.1,
		0.2,
		0.1,
		0.2,
		0.1,
		0.2,
		0.1,
		0.2,
		0.1,
		0.2,
		0.1,
		0.2,
	])) { frame in
		Image(systemName: "\(frame).circle.fill")
			.font(.system(size: 100))
	}
}

#Preview {
	FrameAnimator(.variable(frameDelays: [
		0.01,
		0.02,
		0.01,
		0.02,
		0.01,
		0.02,
		0.01,
		0.02,
		0.01,
		0.02,
		0.01,
		0.02,
		0.01,
		0.02,
		0.01,
		0.02,
		0.01,
		0.02,
		0.01,
		0.02,
		0.01,
		0.02,
	])) { frame in
		Image(systemName: "\(frame).circle.fill")
			.font(.system(size: 100))
	}
}
