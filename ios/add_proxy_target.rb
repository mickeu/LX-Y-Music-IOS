require 'xcodeproj'
project_path = File.expand_path('LxMusicMobile.xcodeproj', File.dirname(__FILE__))
project = Xcodeproj::Project.open(project_path)
return if project.targets.any? { |t| t.name == 'SpotifyProxy' }

main_target = project.targets.find { |t| t.name == 'LxMusicMobile' }
return if main_target.nil?

# 添加 Swift 和 .m 文件到主 App target
['SpotifyProxyServer.swift', 'SpotifyProxyModule.swift', 'SpotifyProxyModule.m'].each do |file|
  ref = main_target.project.main_group.new_reference("LxMusicMobile/#{file}")
  main_target.source_build_phase.add_file_reference(ref, true)
end

project.save
puts 'SpotifyProxy files added successfully'
