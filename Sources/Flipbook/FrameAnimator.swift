//
//  FrameAnimator.swift
//
//
//  Created by Dale Price on 6/30/24.
//

import SwiftUI

public struct FrameAnimator<Timing: FrameTiming, Content: View>: View {
	public var timing: Timing
	public var start: Date
	public var paused: Bool
	@ViewBuilder public var content: (_ frame: Int) -> Content
	
	public init(
		_ timing: Timing,
		start: Date = Date(timeIntervalSince1970: 0),
		paused: Bool = false,
		@ViewBuilder content: @escaping (_ frame: Int) -> Content
	) {
		self.timing = timing
		self.start = start
		self.paused = paused
		self.content = content
	}
	
	private var canAnimate: Bool {
		timing.duration > 0
	}
	
	private func frameIndex(at date: Date) -> Int {
		guard canAnimate else {
			return 0
		}
		let elapsed = date.timeIntervalSince(start).truncatingRemainder(dividingBy: timing.duration)
		return timing.frameIndex(at: elapsed)
	}
	
    public var body: some View {
		if canAnimate {
			TimelineView(timing.timelineSchedule(paused: paused)) { context in
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
