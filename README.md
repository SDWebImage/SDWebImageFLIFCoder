# SDWebImageFLIFCoder

[![CI Status](http://img.shields.io/travis/SDWebImage/SDWebImageFLIFCoder.svg?style=flat)](https://travis-ci.org/SDWebImage/SDWebImageFLIFCoder)
[![Version](https://img.shields.io/cocoapods/v/SDWebImageFLIFCoder.svg?style=flat)](http://cocoapods.org/pods/SDWebImageFLIFCoder)
[![License](https://img.shields.io/cocoapods/l/SDWebImageFLIFCoder.svg?style=flat)](http://cocoapods.org/pods/SDWebImageFLIFCoder)
[![Platform](https://img.shields.io/cocoapods/p/SDWebImageFLIFCoder.svg?style=flat)](http://cocoapods.org/pods/SDWebImageFLIFCoder)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/SDWebImage/SDWebImageFLIFCoder)

## What's for

This is a [SDWebImage](https://github.com/SDWebImage/SDWebImage) coder plugin to add [Free Lossless Image Format](https://flif.info/) support. Which is built based on the open-sourced [libflif](https://github.com/FLIF-hub/FLIF) codec.

This FLIF coder plugin support static FLIF and animated FLIF image decoding and encoding.

## Requirements

+ iOS 8.0
+ macOS 10.10
+ tvOS 9.0
+ watchOS 2.0

## Installation

#### CocoaPods

SDWebImageFLIFCoder is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SDWebImageFLIFCoder'
```

#### Carthage

SDWebImageFLIFCoder is available through [Carthage](https://github.com/Carthage/Carthage). Which use libflif as dynamic framework.

```
github "SDWebImage/SDWebImageFLIFCoder"
```

## Usage

To use FLIF coder, you should firstly add the `SDWebImageFLIFCoder` to the coders manager. Then you can call the View Category method to start load FLIF images.

+ Objective-C

```objective-c
SDImageFLIFCoder *FLIFCoder = [SDImageFLIFCoder sharedCoder];
[[SDImageCodersManager sharedManager] addCoder:FLIFCoder];
UIImageView *imageView;
[imageView sd_setImageWithURL:url];
```

+ Swift

```swift
let FLIFCoder = SDImageFLIFCoder.shared
SDImageCodersManager.shared.addCoder(FLIFCoder)
let imageView: UIImageView
imageView.sd_setImage(with: url)
```

`SDWebImageFLIFCoder` also support FLIF encoding. You can encode `UIImage` to FLIF compressed image data.

+ Objective-C

```objectivec
UIImage *image;
NSData *imageData = [image sd_imageDataAsFormat:SDImageFormatFLIF];
```

+ Swift

```swift
let image;
let imageData = image.sd_imageData(as: .FLIF)
```

## Screenshot

<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImageFLIFCoder/master/Example/Screenshot/FLIFDemo.png" width="300" />
<img src="https://raw.githubusercontent.com/SDWebImage/SDWebImageFLIFCoder/master/Example/Screenshot/FLIFDemo-macOS.png" width="600" />

These FLIF images are from [Phew](https://github.com/sveinbjornt/Phew), you can try the demo with your own FLIF image as well.

## Author

DreamPiggy

## Thanks

[libflif](https://github.com/FLIF-hub/FLIF)
[Phew](https://github.com/sveinbjornt/Phew)

## License

SDWebImageFLIFCoder is available under the MIT license. See the LICENSE file for more info.

