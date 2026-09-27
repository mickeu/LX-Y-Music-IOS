require 'xcodeproj'
project_path = File.expand_path('ios/LxMusicMobile.xcodeproj', File.dirname(__FILE__) + '/..')
project = Xcodeproj::Project.open(project_path)
return if project.targets.any? { |t| t.name == 'WidgetExtension' }
widget_target = project.new_target(:app_extension, 'WidgetExtension', :ios, '16.1')
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.lx.music.widget'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['INFOPLIST_FILE'] = 'WidgetExtension/Info.plist'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
end
['LyricsActivityAttributes.swift', 'LyricsLiveActivity.swift', 'LxMusicWidgetBundle.swift'].each do |file|
  ref = project.new_file_reference(file, "WidgetExtension/#{file}")
  widget_target.source_build_phase.add_file_reference(ref, true)
end
plist_ref = project.new_file_reference('Info.plist', 'LxMusicWidget/Info.plist')
widget_target.resources_build_phase.add_file_reference(plist_ref, true)
main_target = project.targets.find { |t| t.name == 'LxMusicMobile' }
embed_phase = main_target.build_phase('Embed App Extensions') || main_target.new_copy_files_phase('Embed App Extensions', :embed_app_extensions)
copy_ref = embed_phase.add_file_reference(widget_target.product_reference, true)
copy_ref.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
project.save
puts 'LxMusicWidget target added successfully'
