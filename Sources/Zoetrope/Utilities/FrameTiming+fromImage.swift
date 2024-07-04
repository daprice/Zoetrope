//
//  AnimatedImageView+frameTiming.swift
//
//
//  Created by Dale Price on 7/2/24.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension VariableFrameTiming {
	#if canImport(UIKit)
	
	/// Create a ``VariableFrameTiming`` instance that matches the frame delays set on a `UIImage`'s frames.
	///
	/// Returns nil if not all frames have a `frameDelay` property or duration is 0.
	public init?(from image: UIImage) {
		guard let frames = image.images, !frames.isEmpty, image.duration > 0 else {
			return nil
		}
		
		let frameDelays = frames.compactMap { $0.frameDelay }
		if frameDelays.count == frames.count {
			self.init(frameDelays: frameDelays)
		} else {
			return nil
		}
	}
	
	#elseif canImport(AppKit)
	
	/// Create a ``VariableFrameTiming`` instance that matches the frame delays of an `NSImage`'s animatable representation, if it has one.
	///
	/// Returns nil if all frames have the same duration, because ``ConstantFrameTiming`` is more appropriate in that case.
	public init?(from image: NSImage) {
		guard let animatableRep = image.animatableRepresentation, let frameCount = image.animationFrameCount else {
			return nil
		}
		
		var frameDelays: [TimeInterval] = []
		var isVariable = false
		
		for frameIndex in 0..<frameCount {
			animatableRep.setProperty(.currentFrame, withValue: NSNumber(value: frameIndex))
			guard let frameDuration = (animatableRep.value(forProperty: .currentFrameDuration) as? NSNumber)?.doubleValue else {
				return nil
			}
			
			if frameIndex > 0, let lastDelay = frameDelays.last, frameDuration != lastDelay {
				isVariable = true
			}
			
			frameDelays.append(frameDuration)
		}
		
		guard isVariable else { return nil }
		self.init(frameDelays: frameDelays)
	}
	
	#endif
}

extension ConstantFrameTiming {
	#if canImport(UIKit)
	
	/// Create a ``ConstantFrameTiming`` instance that matches the frame count and duration of a `UIImage`.
	///
	/// Returns nil if there are no sub-images or duration is 0.
	public init?(from image: UIImage) {
		guard let frames = image.images, !frames.isEmpty, image.duration > 0 else {
			return nil
		}
		
		self.init(frameCount: frames.count, duration: image.duration)
	}
	
	#elseif canImport(AppKit)
	
	/// Create a ``ConstantFrameTiming`` instance using the frame count and duration of an `NSImage`'s animatable representation, if it has one.
	public init?(from image: NSImage) {
		guard let animatableRep = image.animatableRepresentation, let frameCount = image.animationFrameCount else {
			return nil
		}
		
		var duration: TimeInterval = 0.0
		for frameIndex in 0..<frameCount {
			animatableRep.setProperty(.currentFrame, withValue: NSNumber(value: frameIndex))
			guard let frameDuration = (animatableRep.value(forProperty: .currentFrameDuration) as? NSNumber)?.doubleValue else {
				return nil
			}
			duration += frameDuration
		}
		
		self.init(frameCount: frameCount, duration: duration)
	}
	
	#endif
}
