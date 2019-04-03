#
# Be sure to run `pod lib lint SDWebImageFLIFCoder.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SDWebImageFLIFCoder'
  s.version          = '0.3.0'
  s.summary          = 'A FLIF(Free Lossless Image Format) coder plugin for SDWebImage.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/SDWebImage/SDWebImageFLIFCoder'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'DreamPiggy' => 'lizhuoli1126@126.com' }
  s.source           = { :git => 'https://github.com/SDWebImage/SDWebImageFLIFCoder.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.module_map = 'SDWebImageFLIFCoder/Module/SDWebImageFLIFCoder.modulemap'

  s.source_files = 'SDWebImageFLIFCoder/Classes/**/*', 'Vendor/libflif/include/*.h', 'SDWebImageFLIFCoder/Module/SDWebImageFLIFCoder.h'
  s.public_header_files = 'SDWebImageFLIFCoder/Classes/SDImageFLIFCoder.h', 'SDWebImageFLIFCoder/Module/SDWebImageFLIFCoder.h'

  s.libraries = 'c++'
  s.dependency 'SDWebImage/Core', '~> 5.0'
  s.dependency 'libflif'
end
