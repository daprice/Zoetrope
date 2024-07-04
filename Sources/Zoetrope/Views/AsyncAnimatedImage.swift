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

@available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
public struct AsyncAnimatedImage<Content: View>: View {
	
	public enum Phase: Sendable {
		case empty
		case success(Image)
		case failure(any Error)
		
		public var image: Image? {
			if case .success(let image) = self {
				return image
			} else {
				return nil
			}
		}
		
		public var error: (any Error)? {
			if case .failure(let error) = self {
				return error
			} else {
				return nil
			}
		}
	}
	
	var url: URL
	var start: Date?
	var precacheFrames: Bool = false
	var transaction: Transaction
	@ViewBuilder var content: (Phase) -> Content
	
	#if canImport(UIKit)
	@State private var image: UIImage? = nil
	#elseif canImport(AppKit)
	@State private var image: NSImage? = nil
	#endif
	
	@State private var finishedLoadingDate: Date? = nil
	@State private var error: (any Error)? = nil
	
	/// Loads and plays back an animated image from the specified URL.
	/// - Parameters:
	///   - url: The URL of the image to display.
	///   - start: The `Date` that should be considered as the beginning of the loop for looping images. If `nil`, the loop begins when the image finishes loading. If you provide the same start date to multiple image views, they will play back in sync with each other.
	///   - precacheFrames: Whether or not to decode every frame before displaying the image. For large or high frame rate images, this prevents animation hitching during playback, but increases loading time and uses more memory.
	public init(
		url: URL,
		start: Date? = nil,
		precacheFrames: Bool = false
	) where Content == _ConditionalContent<Image, EmptyView> {
		self.init(
			url: url,
			start: start,
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
	
	public init<I, P>(
		url: URL,
		start: Date? = nil,
		precacheFrames: Bool = false,
		@ViewBuilder content: @escaping (Image) -> I,
		@ViewBuilder placeholder: @escaping () -> P
	) where Content == _ConditionalContent<I, P>, I: View, P: View {
		self.init(
			url: url,
			start: start,
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
	
	public init(
		url: URL,
		start: Date? = nil,
		precacheFrames: Bool = false,
		transaction: Transaction = Transaction(),
		@ViewBuilder content: @escaping (Phase) -> Content
	) {
		self.url = url
		self.start = start
		self.precacheFrames = precacheFrames
		self.transaction = transaction
		self.content = content
	}
	
    public var body: some View {
		ZStack {
			if let image {
				AnimatedImageView(uiImage: image, start: start ?? finishedLoadingDate ?? .now) { image in
					content(.success(image))
				}
			} else if let error {
				content(.failure(error))
			} else {
				content(.empty)
			}
		}
		.task(id: url, priority: .utility) {
			self.finishedLoadingDate = nil
			self.error = nil
			self.image = nil
			
			do {
				let (data, _) = try await URLSession.shared.data(from: url)
				
				#if canImport(UIKit)
				guard let image = UIImage.animatedImage(data: data) else { return }
				
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
				guard let image = NSImage(data: data) else { return }
				// TODO: whatever the AppKit equivalent of preparingForDisplay is
				#endif
				
				self.finishedLoadingDate = .now
				self.image = image
			} catch {
				self.error = error
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
