Pod::Spec.new do |s|
  s.name         = "MK-TZImagePickerController"
  s.version      = "0.0.1"
  s.summary      = "Fork from https://github.com/banchichen/TZImagePickerController"
  s.homepage     = "https://github.com/Mosoink/MK-TZImagePickerController"
  s.license      = "MIT"
  s.author       = { "Mosoink" => "zhibin.cai@mosoink.com" }
  s.platform     = :ios
  s.ios.deployment_target = "6.0"
  s.source       = { :git => "https://github.com/Mosoink/MK-TZImagePickerController.git"}
  s.requires_arc = true
  s.resources    = "TZImagePickerController/**/*.{png,xib,nib,bundle}"
  s.source_files = "TZImagePickerController/*.{h,m}"

  s.frameworks = [
      'AssetsLibrary',
      'MediaPlayer'
  ]
end
