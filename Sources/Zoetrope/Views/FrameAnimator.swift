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
	public var stopped: Bool
	public var loops: UInt?
	@ViewBuilder public var content: (_ frame: Int) -> Content
	
	/// Creates a FrameAnimator view that uses the given timing.
	/// - Parameters:
	///   - timing: A schedule of how and when each frame should be shown. Use a type that conforms to ``FrameTiming``, like ``FrameTiming/constant(frameCount:duration:)`` or ``FrameTiming/variable(frameDelays:)``.
	///   - start: A past or present date that should be considered the starting time of the animation. Creating multiple FrameAnimator views with the same timing and start date causes them to play in sync. To sync animation playback with the time the view appears, use a `@State` variable that you set to `.now` in an `onAppear` modifier.
	///   - paused: Whether the animation should be paused on whichever frame is current as of the time that `paused` is set to `true`.
	///   - stopped: If `true`, prevents the animation from playing and only displays the first frame.
	///   - loops: A limit on how many times the animation can loop starting at the `start` date. `nil` to loop endlessly, `1` to play once, `2` to play twice, and so on.
	///   - content: A closure that generates the view content at a frame index that it takes as input.
	public init(
		_ timing: Timing,
		start: Date = Date(timeIntervalSince1970: 0),
		paused: Bool = false,
		stopped: Bool = false,
		loops: UInt? = nil,
		@ViewBuilder content: @escaping (_ frame: Int) -> Content
	) {
		self.timing = timing
		self.start = start
		self.paused = paused
		self.stopped = stopped
		self.loops = loops
		self.content = content
	}
	
	private var canAnimate: Bool {
		timing.duration > 0 && timing.frameCount > 1
	}
	
	private func frameIndex(at date: Date) -> Int {
		guard canAnimate, !stopped else {
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
			TimelineView(timing.timelineSchedule(paused: paused || hasReachedLoopLimit(at: .now) || stopped, loopStart: start)) { context in
				let frame = frameIndex(at: context.date)
				content(frame)
			}
		} else {
			content(0)
		}
    }
}

#Preview("Constant timing") {
	FrameAnimator(.constant(frameCount: 10, duration: 2)) { frame in
		Image(systemName: "\(frame).circle.fill")
			.font(.system(size: 100))
	}
}

#Preview("Variable timing") {
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

#Preview("Fast variable timing") {
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

#Preview("Very fast variable timing") {
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
