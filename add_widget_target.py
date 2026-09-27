#!/usr/bin/env python3
"""Add LxMusicWidget Widget Extension target to LxMusicMobile.xcodeproj"""
from pbxproj import XcodeProject
from pbxproj.pbxsections.PBXNativeTarget import PBXNativeTarget

proj_path = 'ios/LxMusicMobile.xcodeproj/project.pbxproj'
proj = XcodeProject.load(proj_path)

# 1. 创建 LxMusicWidget group
widget_group = proj.get_or_create_group('LxMusicWidget', path='LxMusicWidget')

# 2. 加文件到 group
proj.add_file('LxMusicWidget/Info.plist', parent=widget_group, force=False)
for f in ['LyricsActivityAttributes.swift', 'LyricsLiveActivity.swift', 'LxMusicWidgetBundle.swift']:
    proj.add_file(f'LxMusicWidget/{f}', parent=widget_group, force=False)

# 3. 创建 Widget Extension target
widget_target = proj.add_target(
    'LxMusicWidget',
    'com.apple.product-type.app-extension',
    None,
)
print(f"Widget target created: {widget_target}")

# 4. 加 Swift 源文件到 widget target 的 Sources build phase
for f in ['LxMusicWidget/LyricsActivityAttributes.swift',
          'LxMusicWidget/LyricsLiveActivity.swift',
          'LxMusicWidget/LxMusicWidgetBundle.swift']:
    proj.add_file(f, target=widget_target, force=False)

# 5. 设置 build settings
for config_name in ['Debug', 'Release']:
    configs = proj.get_build_configurations_by_target('LxMusicWidget')
    if configs:
        for cfg in configs:
            cfg_name = cfg.get('name')
            if cfg_name == config_name:
                cfg['SWIFT_VERSION'] = '5.0'
                cfg['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.LX-YMusic.shuhao.LxMusicWidget'
                cfg['INFOPLIST_FILE'] = 'LxMusicWidget/Info.plist'
                cfg['CODE_SIGNING_ALLOWED'] = 'NO'
                cfg['CODE_SIGNING_REQUIRED'] = 'NO'
                cfg['TARGETED_DEVICE_FAMILY'] = '"1,2"'
                cfg['IPHONEOS_DEPLOYMENT_TARGET'] = '16.1'
                print(f"  Config {config_name} settings applied")

# 6. 加 Widget Extension 的 Info.plist 到 Resources phase
proj.add_file('LxMusicWidget/Info.plist', target=widget_target, force=False)

proj.save()
print("✅ Widget Extension target added!")
