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

#Preview {
	VStack {
		if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
			AsyncAnimatedImage(url: URL(string: "https://files.mastodon.social/accounts/avatars/000/010/843/original/media.gif")! )
		} else {
			EmptyView()
		}
	}
	.frame(width: 200, height: 200)
}
