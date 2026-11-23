Pod::Spec.new do |s|
  s.name             = 'O11A1Bridge'
  s.version          = '0.2.0'
  s.summary          = 'O11A1 loopback Bilibili bridge'
  s.description      = 'Serves the O11A1 web UI on loopback, proxies Bilibili APIs and media, and persists login cookies.'
  s.author           = 'O11A1'
  s.homepage         = 'https://github.com/AntarcticBearHKL/O11A1-Mobile'
  s.platforms        = { :ios => '15.1' }
  s.source           = { :git => 'https://github.com/AntarcticBearHKL/O11A1-Mobile.git', :tag => s.version.to_s }
  s.source_files     = 'ios/**/*.{swift,h,m,mm}'
  s.dependency 'ExpoModulesCore'
  s.frameworks       = 'Foundation', 'Network', 'UIKit', 'CoreImage', 'WebKit', 'QuartzCore'
  s.libraries        = 'compression'
  s.swift_version    = '5.0'
  s.static_framework = true
end
