require 'xcodeproj'
project_path = File.expand_path('LxMusicMobile.xcodeproj', File.dirname(__FILE__))
project = Xcodeproj::Project.open(project_path)

main_target = project.targets.find { |t| t.name == 'LxMusicMobile' }
return if main_target.nil?

# 获取已添加的文件名，避免重复
existing = main_target.source_build_phase.files_references.map { |r| File.basename(r.path.to_s) }

files = ['SpotifyProxyServer.swift', 'SpotifyProxyModule.swift', 'SpotifyProxyModule.m',
         'PlayMediaIntentHandler.h', 'PlayMediaIntentHandler.m', 'Intents.intentdefinition']

added = 0
files.each do |file|
  next if existing.include?(file)
  ref = main_target.project.main_group.new_reference("LxMusicMobile/#{file}")
  main_target.source_build_phase.add_file_reference(ref, true)
  added += 1
end

project.save
puts "Added #{added} files (skipped #{files.size - added} existing)"
