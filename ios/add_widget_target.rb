require 'xcodeproj'
project_path = File.expand_path('LxMusicMobile.xcodeproj', File.dirname(__FILE__))
project = Xcodeproj::Project.open(project_path)
return if project.targets.any? { |t| t.name == 'WidgetExtension' }

# 创建 group
widget_group = project.main_group.new_group('WidgetExtension', 'WidgetExtension')

# 创建 Widget Extension target
widget_target = project.new_target(:app_extension, 'WidgetExtension', :ios, '16.1')
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.lx.music.widget'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['INFOPLIST_FILE'] = 'WidgetExtension/Info.plist'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
end

# 添加 Swift 源文件
['LyricsActivityAttributes.swift', 'LyricsLiveActivity.swift', 'LxMusicWidgetBundle.swift'].each do |file|
  ref = widget_group.new_reference(file)
  widget_target.source_build_phase.add_file_reference(ref, true)
end

# 添加 Info.plist
plist_ref = widget_group.new_reference('Info.plist')
widget_target.resources_build_phase.add_file_reference(plist_ref, true)

# 嵌入主 App
main_target = project.targets.find { |t| t.name == 'LxMusicMobile' }
# 查找或创建 Embed App Extensions phase
embed_phase = main_target.copy_files_build_phases.find { |p| p.name == 'Embed App Extensions' }
if embed_phase.nil?
  embed_phase = main_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = 10 # embed_app_extensions
end
copy_ref = embed_phase.add_file_reference(widget_target.product_reference, true)
copy_ref.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# 添加 target dependency
main_target.add_dependency(widget_target)

project.save
puts 'WidgetExtension target added successfully'
