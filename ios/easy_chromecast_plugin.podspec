Pod::Spec.new do |s|
  s.name             = 'easy_chromecast_plugin'
  s.version          = '1.0.2'
  s.summary          = 'A modern, type-safe Flutter plugin for Google Chromecast.'
  s.homepage         = 'https://pub.dev'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'email@example.com' }
  s.source           = { :path => '.' }
  
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  
  # ---- UNIVERSELE AUTOMATISCHE ZIP EN MAP-FIX ----
  # Dit script zoekt zélf naar de .xcframework map binnen de uitgepakte bestanden
  s.prepare_command = <<-CMD
    rm -rf Frameworks temp_unzip
    mkdir -p Frameworks temp_unzip
    
    # Pak de specifieke 4.8.6 zip uit in de tijdelijke map
    unzip -q GoogleCastSDK-ios-4.8.6_static.zip -d temp_unzip
    
    # Zoek automatisch de .xcframework map op en verplaats deze naar Frameworks/
    XCFRAMEWORK_DIR=$(find temp_unzip -name "GoogleCast.xcframework" -type d -firstbreak 2>/dev/null || find temp_unzip -name "*.xcframework" -type d | head -n 1)
    
    if [ -n "$XCFRAMEWORK_DIR" ]; then
      mv "$XCFRAMEWORK_DIR" Frameworks/GoogleCast.xcframework
    else
      echo "ERROR: Geen .xcframework gevonden in het zip-bestand!"
      exit 1
    fi
    
    # Ruim de tijdelijke map netjes op
    rm -rf temp_unzip
  CMD
  
  # CocoaPods leest het framework nu altijd op de perfecte plek uit!
  s.vendored_frameworks = 'Frameworks/GoogleCast.xcframework'
  s.static_framework = true
  # -----------------------------------------------
  
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
