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
struct AsyncAnimatedImage: View {
	var url: URL
	var precacheFrames: Bool = false
	
	#if canImport(UIKit)
	@State private var image: UIImage? = nil
	#elseif canImport(AppKit)
	@State private var image: NSImage? = nil
	#endif
	
	/// Loads and plays back an animated image from the specified URL.
	/// - Parameters:
	///   - url: The URL of the image to display.
	///   - precacheFrames: Whether or not to decode every frame before displaying the image. For large or high frame rate images, this prevents animation hitching during playback, but increases loading time and uses more memory.
	init(url: URL, precacheFrames: Bool = false) {
		self.url = url
		self.precacheFrames = precacheFrames
	}
	
    var body: some View {
		ZStack {
			if let image {
				AnimatedImageView(uiImage: image) { image in
					image
				}
			}
		}
		.task(id: url, priority: .utility) {
			guard let (data, _) = try? await URLSession.shared.data(from: url) else {
				return
			}
			
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
			
			self.image = image
		}
    }
}

#Preview("WebP (non-macOS only)") {
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


#Preview("Variable frame delay GIF") {
	VStack {
		if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
			AsyncAnimatedImage(url: URL(string: "https://i.sstatic.net/AK9Pj.gif")! )
		} else {
			EmptyView()
		}
	}
	.frame(width: 400, height: 200)
}
