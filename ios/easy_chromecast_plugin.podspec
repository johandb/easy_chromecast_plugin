Pod::Spec.new do |s|
  s.name             = 'easy_chromecast_plugin'
  s.version          = '1.0.11'
  s.summary          = 'A Flutter plugin for Google Chromecast.'
  s.description      = 'A Flutter plugin for Google Chromecast with Volume and Media Status support.'
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  
  # FIX: Vertel CocoaPods dat deze plugin statisch gelinkt moet worden
  s.static_framework = true

  s.dependency 'Flutter'
  s.dependency 'google-cast-sdk'
  s.dependency 'GTMSessionFetcher/Core'

  s.frameworks = 'AVFoundation', 'AVKit', 'MediaAccessibility', 'MediaPlayer', 'CoreGraphics', 'CoreText', 'Foundation', 'UIKit', 'Network'

  s.platform = :ios, '14.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

