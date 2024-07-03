//
//  AnimatedImageView.swift
//
//
//  Created by Dale Price on 7/2/24.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
public struct AnimatedImageView<Content: View>: View {
	#if canImport(UIKit)
	public var image: UIImage
	#elseif canImport(AppKit)
	public var image: NSImage
	#endif
	
	public var start: Date
	public var paused: Bool
	@ViewBuilder public var content: (Image) -> Content
	
	@Environment(\.accessibilityPlayAnimatedImages) private var accessibilityPlayAnimatedImages
	@Environment(\.accessibilityDimFlashingLights) private var accessibilityDimFlashingLights
	
	#if canImport(UIKit)
	public init(
		uiImage image: UIImage,
		start: Date = Date(timeIntervalSince1970: 0),
		paused: Bool = false,
		@ViewBuilder content: @escaping (Image) -> Content
	) {
		self.image = image
		self.start = start
		self.paused = paused
		self.content = content
	}
	#elseif canImport(AppKit)
	public init(
		uiImage image: NSImage,
		start: Date = Date(timeIntervalSince1970: 0),
		paused: Bool = false,
		@ViewBuilder content: @escaping (Image) -> Content
	) {
		self.image = image
		self.start = start
		self.paused = paused
		self.content = content
	}
	#endif
	
	private var accessibilityDontAnimate: Bool {
		accessibilityDimFlashingLights || !accessibilityPlayAnimatedImages
	}
	
	private func image(frame frameIndex: Int) -> Image {
		#if canImport(UIKit)
		return Image(uiImage: image.images?[frameIndex] ?? image)
		#elseif canImport(AppKit)
		guard let animatableRepresentation = image.animatableRepresentation,
			  let cgImage = animatableRepresentation.cgImage(atFrameIndex: frameIndex) else {
			return Image(nsImage: image)
		}
		return Image(decorative: cgImage, scale: image.recommendedLayerContentsScale(0.0))
		#endif
	}
	
	public var body: some View {
		if let variableTiming = Self.variableFrameTiming(for: image) {
			FrameAnimator(variableTiming, start: start, paused: paused, loops: image.loopCount) { frameIndex in
				content(image(frame: frameIndex))
			}
		} else if let constantTiming = Self.constantFrameTiming(for: image) {
			FrameAnimator(constantTiming, start: start, paused: paused, loops: image.loopCount) { frameIndex in
				content(image(frame: frameIndex))
			}
		} else {
			content(image(frame: 0))
		}
    }
}
