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

#if canImport(UIKit)

@available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension AnimatedImageView {
	/// Create a ``VariableFrameTiming`` instance that matches the frame delays set on the image's frames. Nil if not all frames have a `frameDelay` property or duration is 0.
	internal static func variableFrameTiming(for image: UIImage) -> VariableFrameTiming? {
		guard let frames = image.images, !frames.isEmpty, image.duration > 0 else {
			return nil
		}
		
		let frameDelays = frames.compactMap { $0.frameDelay }
		if frameDelays.count == frames.count {
			return VariableFrameTiming(frameDelays: frameDelays)
		} else {
			return nil
		}
	}
	
	/// Create a ``ConstantFrameTiming`` instance that matches the frame count and duration of the image. Nil if there are no sub-images or duration is 0.
	internal static func constantFrameTiming(for image: UIImage) -> ConstantFrameTiming? {
		guard let frames = image.images, !frames.isEmpty, image.duration > 0 else {
			return nil
		}
		
		return ConstantFrameTiming(frameCount: frames.count, duration: image.duration)
	}
}

#elseif canImport(AppKit)

@available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
extension AnimatedImageView {
	// returns nil if all frames have the same duration, as we don't need variable timing for that
	internal static func variableFrameTiming(for image: NSImage) -> VariableFrameTiming? {
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
		return VariableFrameTiming(frameDelays: frameDelays)
	}
	
	internal static func constantFrameTiming(for image: NSImage) -> ConstantFrameTiming? {
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
		
		return ConstantFrameTiming(frameCount: frameCount, duration: duration)
	}
}

#endif
