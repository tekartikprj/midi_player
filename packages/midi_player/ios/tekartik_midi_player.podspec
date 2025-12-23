#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'tekartik_midi_player'
  s.version          = '0.0.1'
  s.summary          = 'Simple midi player.'
  s.description      = <<-DESC
Simple midi player.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'alex@tekartik.com' }
  s.source           = { :path => '.' }
  s.source_files = 'tekartik_midi_player/Sources/tekartik_midi_player/**/*.{h,m}'
  s.public_header_files = 'tekartik_midi_player/Sources/tekartik_midi_player/include/**/*.h'
  s.dependency 'Flutter'
  s.resources = ['tekartik_midi_player/Sources/tekartik_midi_player/Assets/**/*']
  s.resource_bundles = {'tekartik_midi_player_ios_privacy' => ['tekartik_midi_player/Sources/tekartik_midi_player/Resources/PrivacyInfo.xcprivacy']}
  s.ios.deployment_target = '8.0'
end

