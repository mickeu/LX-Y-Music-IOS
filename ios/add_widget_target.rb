require 'xcodeproj'
project_path = File.expand_path('LxMusicMobile.xcodeproj', File.dirname(__FILE__))
project = Xcodeproj::Project.open(project_path)
return if project.targets.any? { |t| t.name == 'WidgetExtension' }

# 创建 group
widget_group = project.main_group.new_group('WidgetExtension', 'WidgetExtension')

# 创建 Widget Extension target
widget_target = project.new_target(:app_extension, 'WidgetExtension', :ios, '16.1')
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.LX-YMusic.shuhao.WidgetExtension'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['INFOPLIST_FILE'] = 'WidgetExtension/Info.plist'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['SKIP_INSTALL'] = 'NO'
  config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
  # xcodeproj 的 :app_extension 模板不会设置 PRODUCT_NAME，必须显式指定。
  # 否则 FULL_PRODUCT_NAME 解析为 ".appex"（空名），导致 bundle 目录创建命令
  # 与链接命令输出到同一路径，报 "Multiple commands produce .../.appex"。
  config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  # 为 appex 扩展显式指定包类型，确保 Info.plist 中 $(PRODUCT_BUNDLE_PACKAGE_TYPE) 正确解析。
  config.build_settings['PRODUCT_BUNDLE_PACKAGE_TYPE'] = 'XPC!'
end

# 添加 Swift 源文件
['LyricsActivityAttributes.swift', 'LyricsLiveActivity.swift', 'LxMusicWidgetBundle.swift'].each do |file|
  ref = widget_group.new_reference(file)
  widget_target.source_build_phase.add_file_reference(ref, true)
end

# Info.plist 不需要加到 Resources phase（Xcode 会自动处理）
plist_ref = widget_group.new_reference('Info.plist')

# 添加 LiveActivityModule 到主 App target
main_target = project.targets.find { |t| t.name == 'LxMusicMobile' }

# 直接使用相对于 ios/ 目录的完整路径
swift_file_ref = main_target.source_build_phase.add_file_reference(
  main_target.project.main_group.new_reference('LxMusicMobile/LiveActivityModule.swift')
)
m_file_ref = main_target.source_build_phase.add_file_reference(
  main_target.project.main_group.new_reference('LxMusicMobile/LiveActivityModule.m')
)

# 嵌入主 App

# 添加 target dependency
main_target.add_dependency(widget_target)

# 添加 Embed App Extensions phase
embed_phase = main_target.copy_files_build_phases.find { |p| p.name == 'Embed App Extensions' }
if embed_phase.nil?
  embed_phase = main_target.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.dst_subfolder_spec = '13' # PlugIns 目录：app 扩展(.appex)必须嵌入 PlugIns 子目录，iOS 才能在运行时发现并加载。('10'=Frameworks 不适用于 app 扩展)
end
# 只添加一次
unless embed_phase.files_references.any? { |f| f.path == widget_target.product_reference.path }
  copy_ref = embed_phase.add_file_reference(widget_target.product_reference, true)
  copy_ref.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

project.save
puts 'WidgetExtension target added successfully'
