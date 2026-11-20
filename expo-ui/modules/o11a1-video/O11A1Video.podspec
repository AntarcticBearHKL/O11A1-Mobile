Pod::Spec.new do |s|
  s.name             = 'O11A1Video'
  s.version          = '0.1.0'
  s.summary          = 'O11A1 VideoToolbox + Metal test player'
  s.description      = 'VideoToolbox hardware decode, Metal frame blending and CAS-like sharpening for the O11A1 mobile lab.'
  s.author           = 'O11A1'
  s.homepage         = 'https://github.com/AntarcticBearHKL/O11A1-Mobile'
  s.platforms        = { :ios => '15.1' }
  s.source           = { :git => 'https://github.com/AntarcticBearHKL/O11A1-Mobile.git', :tag => s.version.to_s }
  s.source_files     = 'ios/**/*.{swift,h,m,mm}'
  s.resources        = 'ios/Resources/*.mp4'
  s.dependency 'ExpoModulesCore'
  s.frameworks       = 'AVFoundation', 'VideoToolbox', 'Metal', 'MetalKit', 'CoreVideo', 'QuartzCore', 'UIKit'
  s.swift_version    = '5.0'
  s.static_framework = true
end
