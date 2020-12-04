Pod::Spec.new do |s|
	s.name             = "imglyKit2"
	s.version          = "1.2.0"
	s.license          = { :type => 'Copyright', :file => 'LICENSE' }
	s.summary          = "Creates stunning images with a nice selection of premium filters."
	s.homepage         = "https://github.com/ky1vstar/imgly-sdk-ios-2"
	s.social_media_url = 'https://twitter.com/9elements'
	s.authors          = { '9elements GmbH' => 'contact@9elements.com', 'ky1vstar' => 'ky1vstar@ex.ua' }
	s.source           = { :git => 'https://github.com/ky1vstar/imgly-sdk-ios-2.git', :tag => s.version.to_s }
    s.module_name      = 'imglyKit'
    s.header_dir       = 'imglyKit'

	s.ios.deployment_target = '8.0'
	s.osx.deployment_target = '10.10'
	
	s.requires_arc = true

    s.swift_version = '5.0'

    s.ios.source_files = ['imglyKit/Backend/**/*.{h,m,swift}', 'imglyKit/Frontend/**/*.{h,m,swift}']
    s.osx.source_files = ['imglyKit/Backend/**/*.{h,m,swift}']

	s.ios.resources = ['imglyKit/Frontend/Assets.xcassets', 'imglyKit/Frontend/en.lproj/Localizable.strings', 'imglyKit/Backend/Filter Responses/*.png', 'imglyKit/Backend/Fonts/*']
	s.osx.resources = ['imglyKit/Backend/Filter Responses/*.png', 'imglyKit/Backend/Fonts/*']

	s.ios.frameworks = 'Accelerate', 'AVFoundation', 'CoreGraphics', 'CoreImage', 'CoreMotion', 'CoreText', 'Foundation', 'GLKit', 'MobileCoreServices', 'OpenGLES', 'Photos', 'UIKit'
	s.osx.frameworks = 'Accelerate', 'AppKit', 'CoreGraphics', 'CoreText', 'Foundation', 'QuartzCore'
end
