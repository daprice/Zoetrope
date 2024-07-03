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
	#if canImport(UIKit)
	@State private var image: UIImage? = nil
	#elseif canImport(AppKit)
	@State private var image: NSImage? = nil
	#endif
	
    var body: some View {
		ZStack {
			if let image {
				AnimatedImageView(uiImage: image) { image in
					image
				}
			}
		}
		.task(id: url) {
			guard let (data, _) = try? await URLSession.shared.data(from: url) else {
				return
			}
			
			#if canImport(UIKit)
			guard let image = UIImage.animatedImage(data: data) else { return }
			#elseif canImport(AppKit)
			guard let image = NSImage(data: data) else { return }
			#endif
			
			self.image = image
		}
    }
}

#Preview("WebP (non-macOS only)") {
	ScrollView {
		VStack {
			if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
				AsyncAnimatedImage(url: URL(string: "https://i.giphy.com/3NtY188QaxDdC.webp")! )
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
