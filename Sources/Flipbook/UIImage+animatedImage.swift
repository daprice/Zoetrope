//
//  UIImage+animatedImage.swift
//
//
//  Created by Dale Price on 6/29/24.
//

#if canImport(UIKit)
import UIKit
import ImageIO
import UniformTypeIdentifiers

extension UIImage {
	/// Creates an animated image from GIF, WebP, APNG, or HEIC data.
	/// - Parameters:
	///   - data: The data object containing the image data.
	///   - fileExtension: Optionally, pass the image's file extension (if known) such as `"gif"`, `"png"`, etc. This provides a hint for determining the format of the image when decoding, but is not strictly necessary.
	/// - Returns: A `UIImage` instance, or nil if the image could not be initialized or the image does not contain frames. The returned `UIImage` will have its `duration` property set to the total animation duration, and its `frames` array will contain the individual frames.
	///
	/// If the image has a variable frame rate, each item in `frames` will have an extra property ``frameDelay`` attached, specifying the duration of that frame.
	///
	/// - Note: You can pass an image created this way to a `UIImageView` and it will animate. However, because `UIImageView` is not aware of the extra ``frameDelay`` property, variable frame rate images will play back at a constant frame rate.
	public static func animatedImage(data: Data, fileExtension: String? = nil) -> UIImage? {
		let options: [AnyHashable: Any]
		if let fileExtension, let type = UTType(filenameExtension: fileExtension) {
			options = [
				kCGImageSourceTypeIdentifierHint: type.identifier
			]
		} else {
			options = [:]
		}
		guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }
		
		let frameCount = CGImageSourceGetCount(source)
		var frames: [(UIImage, Double)] = []
		frames.reserveCapacity(frameCount)
		var duration = 0.0
		var isConstantFrameRate = true
		
		for frameIndex in 0..<frameCount {
			guard let cgImage = CGImageSourceCreateImageAtIndex(source, frameIndex, nil),
				  let frameDelay = source.frameDelayAtIndex(frameIndex) else { continue }
			
			duration += frameDelay
			let frame = UIImage(cgImage: cgImage)
			frames.append((frame, frameDelay))
			
			// If the frame delay doesn't match that of the first frame, the image is variable frame rate
			if frameIndex >= 1 {
				if frameDelay != frames[0].1 {
					isConstantFrameRate = false
				}
			}
		}
		
		// If the image is variable frame rate, store the frame delay values as associated objects on the UIImage instances.
		if !isConstantFrameRate {
			for (frame, delay) in frames {
				frame.frameDelay = delay
			}
		}
		
		guard !frames.isEmpty else { return nil }
		
		return UIImage.animatedImage(with: frames.map { $0.0 }, duration: duration)
		// TODO: read and do something with the loop count from the gif
	}
}

extension UIImage {
	private static let frameDelayKey = "frameDelay"
	
	/// An associated object specifying the frame delay. This is non-nil on the contents of `frames` on a `UIImage` initialized using ``animatedImage(data:fileExtension:)``.
	public var frameDelay: Double? {
		get {
			return (objc_getAssociatedObject(self, Self.frameDelayKey) as? NSNumber)?.doubleValue
		}
		
		set {
			if let value = newValue {
				objc_setAssociatedObject(self, Self.frameDelayKey, NSNumber(value: value), .OBJC_ASSOCIATION_RETAIN)
			}
		}
	}
}

extension CGImageSource {
	internal func frameDelayAtIndex(_ index: Int) -> Double? {
		guard let properties = CGImageSourceCopyPropertiesAtIndex(self, index, nil) else {
			return nil
		}
		
		let clampedFrameDelay: Double
		let unclampedFrameDelay: Double
		
		if let gifInfo = (properties as NSDictionary)[kCGImagePropertyGIFDictionary] as? NSDictionary,
		   let gifUnclampedDelay = (gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber)?.doubleValue,
		   let gifClampedDelay = (gifInfo[kCGImagePropertyGIFDelayTime as String] as? NSNumber)?.doubleValue {
			unclampedFrameDelay = gifUnclampedDelay
			clampedFrameDelay = gifClampedDelay
		} else if let pngInfo = (properties as NSDictionary)[kCGImagePropertyPNGDictionary] as? NSDictionary,
				  let pngUnclampedDelay = (pngInfo[kCGImagePropertyAPNGUnclampedDelayTime as String] as? NSNumber)?.doubleValue,
				  let pngClampedDelay = (pngInfo[kCGImagePropertyAPNGDelayTime as String] as? NSNumber)?.doubleValue {
			unclampedFrameDelay = pngUnclampedDelay
			clampedFrameDelay = pngClampedDelay
		} else if let webpInfo = (properties as NSDictionary)[kCGImagePropertyWebPDictionary] as? NSDictionary,
				 let webpUnclampedDelay = (webpInfo[kCGImagePropertyWebPUnclampedDelayTime as String] as? NSNumber)?.doubleValue,
				 let webpClampedDelay = (webpInfo[kCGImagePropertyWebPDelayTime as String] as? NSNumber)?.doubleValue {
			unclampedFrameDelay = webpUnclampedDelay
			clampedFrameDelay = webpClampedDelay
		} else if let heicsInfo = (properties as NSDictionary)[kCGImagePropertyHEICSDictionary] as? NSDictionary,
				  let heicsUnclampedDelay = (heicsInfo[kCGImagePropertyHEICSUnclampedDelayTime as String] as? NSNumber)?.doubleValue,
				  let heicsClampedDelay = (heicsInfo[kCGImagePropertyHEICSDelayTime as String] as? NSNumber)?.doubleValue {
			unclampedFrameDelay = heicsUnclampedDelay
			clampedFrameDelay = heicsClampedDelay
		} else {
			return nil
		}
		
		// use the unclamped frame delay unless it is less than or equal to 10ms, in which case use the clamped delay.
		// see https://stackoverflow.com/a/17824564/6833424, apparently this is how WebKit handles it due to bizarre legacy compatibility issues.
		// I've tested a few gifs that have frame durations less equal or less than 10ms and every browser on macOS seems to clamp them like this. 🤷🏻‍♂️
		return unclampedFrameDelay > 0.01 ? unclampedFrameDelay : clampedFrameDelay
	}
}
#endif
