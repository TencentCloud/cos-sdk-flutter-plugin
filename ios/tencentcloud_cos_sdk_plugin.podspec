#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint cos.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'tencentcloud_cos_sdk_plugin'
  s.version          = '1.0.2'
  s.summary          = 'Tencent COS Flutter Plugin SDK.'
  s.description      = <<-DESC
Tencent COS Flutter Plugin SDK.
                       DESC
  s.homepage         = 'https://cloud.tencent.com/document/product/436/6474'
  s.license          = { :file => '../LICENSE' }
  s.author           = { "QCloudTerminalLab" => "g_PDTC_storage_DEV_terminallab@tencent.com" }
#   s.author           = { 'Tencent' => 'jordanqin@tencent.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'QCloudCOSXML','>= 6.1.7'
  s.platform = :ios, '9.0'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
end
