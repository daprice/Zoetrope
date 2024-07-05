# ``Zoetrope``

Create frame-based animations in SwiftUI, including support for animated images.

## Overview

Zoetrope provides three native SwiftUI views: 
- term ``FrameAnimator``: a versatile wrapper around TimelineView for creating frame-based animations
- term ``AnimatedImageView``: for playing back animated UIImage or NSImage instances
- term ``AsyncAnimatedImage``: loads and plays images from URLs, similar to SwiftUI's AsyncImage.

All three views allow you to specify a start date to animate relative to. This allows you to synchronize playback across multiple views, or even multiple devices as long as their clocks are in sync.

> Experiment: Social apps that support looping GIF avatars (like Mastodon/Fediverse clients) could use a profile's creation date as the animation start date. If two people in the same room were looking at the same profile or post, they'd see the avatars playing in sync between their devices. Magic!

### Image format support

On UIKit platforms (iOS, iPadOS, visionOS, tvOS, watchOS, Mac Catalyst), Zoetrope supports animated GIF, WebP, HEIC, or APNG files, all using native UIImage.
> Note: Support is provided using a special UIImage initializer that uses the native ImageIO framework to read those formats, storing any extra metadata (such as loop count and variable frame rate, if applicable) as Associated Objects on the UIImage instance itself. Zoetrope's image view can also play animated UIImage instances created using UIKit's built-in `UIImage.animatedImage` methods.

On AppKit platforms (native macOS), Zoetrope relies on NSImage's built-in support for animated GIF files.

### Examples

`Sources/Views/FrameAnimator.swift` and `Sources/Views/AsyncAnimatedImage.swift` include Xcode previews with examples.

## Topics

### Creating frame-based animations

- ``FrameAnimator``
- ``FrameTiming``
- ``ConstantFrameTiming``
- ``VariableFrameTiming``

### Loading animated images

- ``UIKit/UIImage/animatedImage(data:fileExtension:)``
- ``UIKit/UIImage/loopCount``
- ``UIKit/UIImage/frameDelay``

### Displaying animated images

- ``AnimatedImageView``
- ``AsyncAnimatedImage``
