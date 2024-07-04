//
//  AsyncAnimatedImage.swift
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

public enum AsyncAnimatedImageError: Error {
	case couldNotDecodeImage
}

/// A view that loads an animated image from a URL and plays it back.
///
/// This view uses the shared `URLSession` and otherwise provides similar functionality to SwiftUI's built-in `AsyncImage`. If you implement your own loading system or custom processing, create images using ``UIKit/UIImage/animatedImage(data:fileExtension:)`` or any `NSImage` initializer, and display them using ``AnimatedImageView``.
@available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
public struct AsyncAnimatedImage<Content: View>: View {
	
	var url: URL
	var start: Date?
	var paused: Bool
	var stopped: Bool
	var precacheFrames: Bool = false
	var transaction: Transaction
	@ViewBuilder var content: (AsyncImagePhase) -> Content
	
	#if canImport(UIKit)
	@State private var image: UIImage? = nil
	#elseif canImport(AppKit)
	@State private var image: NSImage? = nil
	#endif
	
	@State private var finishedLoadingDate: Date? = nil
	@State private var error: (any Error)? = nil
	
	/// Loads and plays back an animated image from the specified URL.
	///
	/// Displays EmptyView until the image finishes loading. To customize the placeholder, or use Image-specific modifiers, use ``init(url:start:paused:stopped:precacheFrames:content:placeholder:)`` or ``init(url:start:paused:stopped:precacheFrames:transaction:content:)``.
	///
	/// - Parameters:
	///   - url: The URL of the image to display.
	///   - start: The `Date` that should be considered as the beginning of the loop for looping images. If `nil`, the loop begins when the image finishes loading. If you provide the same start date to multiple image views, they will play back in sync with each other.
	///   - paused: Whether the animation should be paused on whichever frame is current as of the time that `paused` is set to `true`.
	///   - stopped: If `true`, prevents the animation from playing and only displays the first frame.
	///   - precacheFrames: Whether or not to decode every frame before displaying the image. For large or high frame rate images, this prevents animation hitching during playback, but increases loading time and uses more memory. Has no effect on AppKit platforms (macOS).
	public init(
		url: URL,
		start: Date? = nil,
		paused: Bool = false,
		stopped: Bool = false,
		precacheFrames: Bool = false
	) where Content == _ConditionalContent<Image, EmptyView> {
		self.init(
			url: url,
			start: start,
			paused: paused,
			stopped: stopped,
			precacheFrames: precacheFrames,
			content: { phase in
				if let image = phase.image {
					image
				} else {
					EmptyView()
				}
			}
		)
	}
	
	/// Loads and plays back a modifiable image from the specified URL using a custom placeholder until it finishes loading.
	///
	/// If an error occurs, the placeholder will show indefinitely. To customize error handling, use ``init(url:start:paused:stopped:precacheFrames:transaction:content:)``.
	///
	/// - Parameters:
	///   - url: The URL of the image to display.
	///   - start: The `Date` that should be considered as the beginning of the loop for looping images. If `nil`, the loop begins when the image finishes loading. If you provide the same start date to multiple image views, they will play back in sync with each other.
	///   - paused: Whether the animation should be paused on whichever frame is current as of the time that `paused` is set to `true`.
	///   - stopped: If `true`, prevents the animation from playing and only displays the first frame.
	///   - precacheFrames: Whether or not to decode every frame before displaying the image. For large or high frame rate images, this prevents animation hitching during playback, but increases loading time and uses more memory. Has no effect on AppKit platforms (macOS).
	///   - content: A closure that receives an Image view for each frame and generates the view to show. You can return the image directly, or modify it as needed.
	///   - placeholder: A closure that returns a view to show until loading finishes.
	public init<I, P>(
		url: URL,
		start: Date? = nil,
		paused: Bool = false,
		stopped: Bool = false,
		precacheFrames: Bool = false,
		@ViewBuilder content: @escaping (Image) -> I,
		@ViewBuilder placeholder: @escaping () -> P
	) where Content == _ConditionalContent<I, P>, I: View, P: View {
		self.init(
			url: url,
			start: start,
			paused: paused,
			stopped: stopped,
			precacheFrames: precacheFrames,
			content: { phase in
				if let image = phase.image {
					content(image)
				} else {
					placeholder()
				}
			}
		)
	}
	
	/// Loads and displays a modifiable image from the specified URL in phases.
	/// - Parameters:
	///	  - url: The URL of the image to display.
	///   - start: The `Date` that should be considered as the beginning of the loop for looping images. If `nil`, the loop begins when the image finishes loading. If you provide the same start date to multiple image views, they will play back in sync with each other.
	///   - paused: Whether the animation should be paused on whichever frame is current as of the time that `paused` is set to `true`.
	///   - stopped: If `true`, prevents the animation from playing and only displays the first frame.
	///   - precacheFrames: Whether or not to decode every frame before displaying the image. For large or high frame rate images, this prevents animation hitching during playback, but increases loading time and uses more memory. Has no effect on AppKit platforms (macOS).
	///   - transaction: The transaction to use when the phase changes.
	///   - content: A closure that takes the load phase as input, and returns the view to display for the specified phase. As the image plays back, the closure will be called with a `.success` value for each individual frame of the animation.
	public init(
		url: URL,
		start: Date? = nil,
		paused: Bool = false,
		stopped: Bool = false,
		precacheFrames: Bool = false,
		transaction: Transaction = Transaction(),
		@ViewBuilder content: @escaping (AsyncImagePhase) -> Content
	) {
		self.url = url
		self.start = start
		self.paused = paused
		self.stopped = stopped
		self.precacheFrames = precacheFrames
		self.transaction = transaction
		self.content = content
	}
	
    public var body: some View {
		ZStack {
			if let image {
				#if canImport(UIKit)
				AnimatedImageView(uiImage: image, start: start ?? finishedLoadingDate ?? .now) { image in
					content(.success(image))
				}
				#elseif canImport(AppKit)
				AnimatedImageView(nsImage: image, start: start ?? finishedLoadingDate ?? .now) { image in
					content(.success(image))
				}
				#endif
			} else if let error {
				content(.failure(error))
			} else {
				content(.empty)
			}
		}
		.task(id: url, priority: .utility) {
			withTransaction(transaction) {
				self.finishedLoadingDate = nil
				self.error = nil
				self.image = nil
			}
			
			do {
				let (data, _) = try await URLSession.shared.data(from: url)
				
				#if canImport(UIKit)
				guard let image = UIImage.animatedImage(data: data) else {
					throw AsyncAnimatedImageError.couldNotDecodeImage
				}
				
				try Task.checkCancellation()
				if precacheFrames, let frames = image.images {
					await withTaskGroup(of: Void.self) { group in
						for frame in frames {
							group.addTask {
								// By calling this, we cause the CGImageSource to cache the decoded image, so it will be ready when used even though we don't do anything with the decoded image here.
								// If we use await byPreparingForDisplay(), in theory that would be better because it's non-blocking, but for whatever reason it seems to decode all the frames serially even though we're calling it from multiple tasks. The synchronous version we use here decodes frames in parallel across multiple CPU cores, resulting in the image being ready much faster.
								frame.preparingForDisplay()
							}
						}
					}
				}
				
				#elseif canImport(AppKit)
				guard let image = NSImage(data: data) else {
					throw AsyncAnimatedImageError.couldNotDecodeImage
				}
				#endif
				
				try Task.checkCancellation()
				
				withTransaction(transaction) {
					self.finishedLoadingDate = .now
					self.image = image
				}
			} catch {
				withTransaction(transaction) {
					self.error = error
				}
			}
		}
    }
}

#Preview("Variable frame delay GIF with placeholder") {
	VStack {
		if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
			AsyncAnimatedImage(url: URL(string: "https://i.sstatic.net/AK9Pj.gif")! ) { image in
				image
			} placeholder: {
				ProgressView()
			}
		} else {
			EmptyView()
		}
	}
	.frame(width: 400, height: 200)
}

#Preview("WebP (animates on non-macOS only)") {
	// On macOS, NSImage doesn't support animated webp files (as of Sonoma), so this just shows as a static image.
	ScrollView {
		VStack {
			if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
				AsyncAnimatedImage(url: URL(string: "https://i.giphy.com/3NtY188QaxDdC.webp")!, precacheFrames: true )
			} else {
				EmptyView()
			}
		}
		.frame(width: 500, height: 500)
	}
}
