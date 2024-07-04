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

/// A view that plays back an animated `UIImage` or `NSImage`.
///
/// This view stops playback if the user has disabled Accessibility > Play Animated Images, according to `EnvironmentValues.accessibilityPlayAnimatedImages`. Also consider stopping playback (by setting `stopped` to `true`) or reducing contrast if `accessibilityDimFlashingLights` is enabled, and stop playback of large images if `accessibilityReduceMotion` is enabled, as appropriate for your use case.
///
/// To create an animated `UIImage`, use ``UIKit/UIImage/animatedImage(data:fileExtension:)``, `UIImage.animatedImage(with:duration:)`, or `UIImage.animatedImageNamed(_:duration:)`.
///
/// To create an animated `NSImage`, decode an animated GIF file. The `NSImage` must use an `NSBitmapImageRep` that has the `currentFrame`, `currentFrameDuration`, and `frameCount` properties.
@available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
public struct AnimatedImageView<Content: View>: View {
	#if canImport(UIKit)
	public var image: UIImage
	#elseif canImport(AppKit)
	public var image: NSImage
	#endif
	
	public var start: Date
	public var paused: Bool
	public var stopped: Bool
	@ViewBuilder public var content: (Image) -> Content
	
	@Environment(\.accessibilityPlayAnimatedImages) private var accessibilityPlayAnimatedImages
	
#if canImport(UIKit)
	/// Create a view that plays back an animated `UIImage`.
	/// - Parameters:
	///   - image: A `UIImage` instance that plays back if it has a nonzero `duration` and multiple frames in `images`.
	///   - start: A past or present date that should be considered the starting time of the animation. Creating multiple FrameAnimator views with the same timing and start date causes them to play in sync. To sync animation playback with the time the view appears, use a `@State` variable that you set to `.now` in an `onAppear` modifier.
	///   - paused: Whether the animation should be paused on whichever frame is current as of the time that `paused` is set to `true`.
	///   - stopped: If `true`, prevents the animation from playing and only displays the first frame.
	///   - content: A closure that takes a SwiftUI `Image` view for each frame of the animation and produces the content of the view.
	public init(
		uiImage image: UIImage,
		start: Date = Date(timeIntervalSince1970: 0),
		paused: Bool = false,
		stopped: Bool = false,
		@ViewBuilder content: @escaping (Image) -> Content
	) {
		self.image = image
		self.start = start
		self.paused = paused
		self.stopped = stopped
		self.content = content
	}
	#elseif canImport(AppKit)
	/// Create a view that plays back an animated `NSImage`.
	/// - Parameters:
	///   - image: A `NSImage` instance created from an animated GIF file.
	///   - start: A past or present date that should be considered the starting time of the animation. Creating multiple FrameAnimator views with the same timing and start date causes them to play in sync. To sync animation playback with the time the view appears, use a `@State` variable that you set to `.now` in an `onAppear` modifier.
	///   - paused: Whether the animation should be paused on whichever frame is current as of the time that `paused` is set to `true`.
	///   - stopped: If `true`, prevents the animation from playing and only displays the first frame.
	///   - content: A closure that takes a SwiftUI `Image` view for each frame of the animation and produces the content of the view.
	public init(
		nsImage image: NSImage,
		start: Date = Date(timeIntervalSince1970: 0),
		paused: Bool = false,
		stopped: Bool = false,
		@ViewBuilder content: @escaping (Image) -> Content
	) {
		self.image = image
		self.start = start
		self.paused = paused
		self.stopped = stopped
		self.content = content
	}
	#endif
	
	private var accessibilityDontAnimate: Bool {
		!accessibilityPlayAnimatedImages
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
		if let variableTiming = VariableFrameTiming(from: image) {
			FrameAnimator(variableTiming, start: start, paused: paused, loops: image.loopCount) { frameIndex in
				content(image(frame: frameIndex))
			}
		} else if let constantTiming = ConstantFrameTiming(from: image) {
			FrameAnimator(constantTiming, start: start, paused: paused, loops: image.loopCount) { frameIndex in
				content(image(frame: frameIndex))
			}
		} else {
			content(image(frame: 0))
		}
    }
}
