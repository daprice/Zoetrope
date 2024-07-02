import XCTest
@testable import Zoetrope

final class VariableFrameTimingTests: XCTestCase {
	func testVariableTimingInit() throws {
		let now = Date.now
		let testTiming = VariableFrameTiming(frameDelays: [
			1,
			2,
			3,
		], from: now)
		
		XCTAssertEqual(testTiming.duration, 6.0)
		XCTAssertEqual(testTiming.frameCount, 3)
		XCTAssertEqual(testTiming.frameOffsets, [
			0,
			1,
			3,
		])
		XCTAssertEqual(testTiming.frameIndex(at: 0), 0)
		XCTAssertEqual(testTiming.frameIndex(at: 0.4), 0)
		XCTAssertEqual(testTiming.frameIndex(at: 0.9), 0)
		XCTAssertEqual(testTiming.frameIndex(at: 1), 1)
		XCTAssertEqual(testTiming.frameIndex(at: 1.1), 1)
		XCTAssertEqual(testTiming.frameIndex(at: 2.9), 1)
		XCTAssertEqual(testTiming.frameIndex(at: 3), 2)
		XCTAssertEqual(testTiming.frameIndex(at: 4), 2)
		XCTAssertEqual(testTiming.frameIndex(at: 5.9), 2)
		
		XCTAssertEqual(testTiming.frameIndex(at: now.addingTimeInterval(0.9).timeIntervalSince(now)), 0)
		XCTAssertEqual(testTiming.frameIndex(at: now.addingTimeInterval(5.9).timeIntervalSince(now)), 2)
	}
}
