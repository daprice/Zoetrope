//
//  File.swift
//  
//
//  Created by Dale Price on 7/2/24.
//

import Foundation
#if canImport(AppKit)
import AppKit


internal extension NSImage {
	var animatableRepresentation: NSBitmapImageRep? {
		let bitmapRepresentations: [NSBitmapImageRep] = self.representations.compactMap({ $0 as? NSBitmapImageRep })
		return bitmapRepresentations.first(where: { rep in
			guard let frameCount = rep.value(forProperty: .frameCount) as? NSNumber else { return false }
			return frameCount.intValue > 1
		})
	}
	
	var animationFrameCount: Int? {
		(self.animatableRepresentation?.value(forProperty: .frameCount) as? NSNumber)?.intValue
	}
	
	var loopCount: UInt? {
		guard let loopCount = (self.animatableRepresentation?.value(forProperty: .loopCount) as? NSNumber)?.uintValue else {
			return nil
		}
		return loopCount > 0 ? loopCount : nil
	}
}

internal extension NSBitmapImageRep {
	/// The total duration of all animation frames.
	///
	/// - Warning: Computing this variable is expensive because it requires reading every frame individually.
	var animationDuration: Double? {
		guard let frameCount = (value(forProperty: .frameCount) as? NSNumber)?.intValue,
			  frameCount > 1 else {
			return nil
		}
		var totalDuration: Double = 0.0
		for frameIndex in 0..<frameCount {
			setProperty(.currentFrame, withValue: NSNumber(value: frameIndex))
			guard let frameDuration = (value(forProperty: .currentFrameDuration) as? NSNumber)?.doubleValue else {
				return nil
			}
			totalDuration += frameDuration
		}
		return totalDuration
	}
	
	func cgImage(atFrameIndex frameIndex: Int) -> CGImage? {
		setProperty(.currentFrame, withValue: NSNumber(value: frameIndex))
		return self.cgImage
	}
}
#endif

