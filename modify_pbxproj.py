#!/usr/bin/env python3
"""直接文本操作修改 pbxproj，加 Widget Extension target"""
import re, uuid

def gen_id():
    return uuid.uuid4().hex[:24].upper()

pbx_path = 'ios/LxMusicMobile.xcodeproj/project.pbxproj'
with open(pbx_path, 'r') as f:
    content = f.read()

# 生成所有需要的 UUID
ids = {
    'widget_target': gen_id(),
    'widget_product_ref': gen_id(),
    'widget_config_list': gen_id(),
    'widget_config_debug': gen_id(),
    'widget_config_release': gen_id(),
    'widget_sources_phase': gen_id(),
    'widget_resources_phase': gen_id(),
    'widget_frameworks_phase': gen_id(),
    'swift1_fileref': gen_id(),
    'swift1_buildfile': gen_id(),
    'swift2_fileref': gen_id(),
    'swift2_buildfile': gen_id(),
    'swift3_fileref': gen_id(),
    'swift3_buildfile': gen_id(),
    'info_fileref': gen_id(),
    'info_buildfile': gen_id(),
    'widget_group': gen_id(),
    'widget_appex_fileref': gen_id(),
    'embed_phase': gen_id(),
    'embed_buildfile': gen_id(),
    'container_proxy': gen_id(),
    'target_dependency': gen_id(),
}

BUNDLE_ID = 'com.LX-YMusic.shuhao.LxMusicWidget'

# 1. PBXBuildFile section: 加 Widget 源文件 + Info.plist + embed
build_file_marker = '/* End PBXBuildFile section */'
new_build_files = f"""\t\t{ids['swift1_buildfile']} /* LyricsActivityAttributes.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {ids['swift1_fileref']} /* LyricsActivityAttributes.swift */; }};
\t\t{ids['swift2_buildfile']} /* LyricsLiveActivity.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {ids['swift2_fileref']} /* LyricsLiveActivity.swift */; }};
\t\t{ids['swift3_buildfile']} /* LxMusicWidgetBundle.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {ids['swift3_fileref']} /* LxMusicWidgetBundle.swift */; }};
\t\t{ids['info_buildfile']} /* Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['info_fileref']} /* Info.plist */; }};
\t\t{ids['embed_buildfile']} /* LxMusicWidget.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = {ids['widget_appex_fileref']} /* LxMusicWidget.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};
{build_file_marker}"""
content = content.replace(build_file_marker, new_build_files)

# 2. PBXFileReference section: 加 Widget 产物 + Swift 文件 + Info.plist
file_ref_marker = '/* End PBXFileReference section */'
new_file_refs = f"""\t\t{ids['widget_appex_fileref']} /* LxMusicWidget.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = LxMusicWidget.appex; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{ids['swift1_fileref']} /* LyricsActivityAttributes.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LyricsActivityAttributes.swift; sourceTree = "<group>"; }};
\t\t{ids['swift2_fileref']} /* LyricsLiveActivity.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LyricsLiveActivity.swift; sourceTree = "<group>"; }};
\t\t{ids['swift3_fileref']} /* LxMusicWidgetBundle.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LxMusicWidgetBundle.swift; sourceTree = "<group>"; }};
\t\t{ids['info_fileref']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
{file_ref_marker}"""
content = content.replace(file_ref_marker, new_file_refs)

# 3. PBXGroup: 加 LxMusicWidget group + 把它加到主 group
group_marker = '/* End PBXGroup section */'
new_group = f"""\t\t{ids['widget_group']} /* LxMusicWidget */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{ids['swift1_fileref']} /* LyricsActivityAttributes.swift */,
\t\t\t\t{ids['swift2_fileref']} /* LyricsLiveActivity.swift */,
\t\t\t\t{ids['swift3_fileref']} /* LxMusicWidgetBundle.swift */,
\t\t\t\t{ids['info_fileref']} /* Info.plist */,
\t\t\t);
\t\t\tpath = LxMusicWidget;
\t\t\tsourceTree = "<group>";
\t\t}};
{group_marker}"""
content = content.replace(group_marker, new_group)

# 把 widget group 加到主 group（找 children 列表里有 AppDelegate 的位置）
content = content.replace(
    '\t\t\t\t13B07FAF1A68108700A75B9A /* AppDelegate.h */,',
    f'\t\t\t\t13B07FAF1A68108700A75B9A /* AppDelegate.h */,\n\t\t\t\t{ids["widget_group"]} /* LxMusicWidget */,'
)

# 4. PBXNativeTarget: 加 Widget Extension target
target_marker = '/* End PBXNativeTarget section */'
new_target = f"""\t\t{ids['widget_target']} /* LxMusicWidget */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {ids['widget_config_list']} /* Build configuration list for PBXNativeTarget "LxMusicWidget" */;
\t\t\tbuildPhases = (
\t\t\t\t{ids['widget_sources_phase']} /* Sources */,
\t\t\t\t{ids['widget_frameworks_phase']} /* Frameworks */,
\t\t\t\t{ids['widget_resources_phase']} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = LxMusicWidget;
\t\t\tproductName = LxMusicWidget;
\t\t\tproductReference = {ids['widget_appex_fileref']} /* LxMusicWidget.appex */;
\t\t\tproductType = "com.apple.product-type.app-extension";
\t\t}};
{target_marker}"""
content = content.replace(target_marker, new_target)

# 5. PBXSourcesBuildPhase: Widget 的 Sources
sources_marker = '/* End PBXSourcesBuildPhase section */'
new_sources = f"""\t\t{ids['widget_sources_phase']} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{ids['swift1_buildfile']} /* LyricsActivityAttributes.swift in Sources */,
\t\t\t\t{ids['swift2_buildfile']} /* LyricsLiveActivity.swift in Sources */,
\t\t\t\t{ids['swift3_buildfile']} /* LxMusicWidgetBundle.swift in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
{sources_marker}"""
content = content.replace(sources_marker, new_sources)

# 6. PBXResourcesBuildPhase: Widget 的 Resources
resources_marker = '/* End PBXResourcesBuildPhase section */'
new_resources = f"""\t\t{ids['widget_resources_phase']} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{ids['info_buildfile']} /* Info.plist in Resources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
{resources_marker}"""
content = content.replace(resources_marker, new_resources)

# 7. PBXFrameworksBuildPhase: Widget 的 Frameworks
frameworks_marker = '/* End PBXFrameworksBuildPhase section */'
new_frameworks = f"""\t\t{ids['widget_frameworks_phase']} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
{frameworks_marker}"""
content = content.replace(frameworks_marker, new_frameworks)

# 8. PBXCopyFilesBuildPhase: 主 App 的 Embed App Extensions
# 找主 App 的 buildPhases，在最后加 embed phase
# 在 PBXCopyFilesBuildPhase section 加一个新 entry
copyfiles_marker = '/* End PBXCopyFilesBuildPhase section */'
if copyfiles_marker in content:
    new_copy = f"""\t\t{ids['embed_phase']} /* Embed App Extensions */ = {{
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 10;
\t\t\tfiles = (
\t\t\t\t{ids['embed_buildfile']} /* LxMusicWidget.appex in Embed App Extensions */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
{copyfiles_marker}"""
    content = content.replace(copyfiles_marker, new_copy)

    # 把 embed phase 加到主 target 的 buildPhases
    # 找 LxMusicMobile target 的 buildPhases（13B07F841A680F5B00A75B9A）
    main_target_phases = 'buildPhases = (\n\t\t\t\t13B07FBC1A68108700A75B9A /* Sources */,\n\t\t\t\t13B07FC01A68108700A75B9A /* Resources */,'
    if main_target_phases in content:
        content = content.replace(
            main_target_phases,
            main_target_phases + f'\n\t\t\t\t{ids["embed_phase"]} /* Embed App Extensions */,'
        )
        print("✅ Embed phase added to main target")
    else:
        print("⚠️ Could not find main target buildPhases, trying alternate")
        # 找 Resources phase 后面加
        content = content.replace(
            '13B07FC01A68108700A75B9A /* Resources */,',
            f'13B07FC01A68108700A75B9A /* Resources */,\n\t\t\t\t{ids["embed_phase"]} /* Embed App Extensions */,'
        )

# 9. PBXContainerItemProxy + PBXTargetDependency: 主 App 依赖 Widget
container_marker = '/* End PBXContainerItemProxy section */'
if container_marker in content:
    new_proxy = f"""\t\t{ids['container_proxy']} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = 83CBB9FE71B1A5C200B7A4D7 /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {ids['widget_target']};
\t\t\tremoteInfo = LxMusicWidget;
\t\t}};
{container_marker}"""
    content = content.replace(container_marker, new_proxy)

    dep_marker = '/* End PBXTargetDependency section */'
    new_dep = f"""\t\t{ids['target_dependency']} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {ids['widget_target']} /* LxMusicWidget */;
\t\t\ttargetProxy = {ids['container_proxy']} /* PBXContainerItemProxy */;
\t\t}};
{dep_marker}"""
    content = content.replace(dep_marker, new_dep)

    # 把 dependency 加到主 target 的 dependencies 列表
    content = content.replace(
        'dependencies = (\n\t\t\t);\n\t\t\tname = LxMusicMobile;',
        f'dependencies = (\n\t\t\t\t{ids["target_dependency"]} /* PBXTargetDependency */,\n\t\t\t);\n\t\t\tname = LxMusicMobile;'
    )

# 10. XCBuildConfiguration: Widget 的 Debug + Release 配置
xcbuild_marker = '/* End XCBuildConfiguration section */'
new_configs = f"""\t\t{ids['widget_config_debug']} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME = WidgetBackground;
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = LxMusicWidget/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.1;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks";
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{ids['widget_config_release']} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME = WidgetBackground;
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_FILE = LxMusicWidget/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.1;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks";
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
{xcbuild_marker}"""
content = content.replace(xcbuild_marker, new_configs)

# 11. XCConfigurationList: Widget 的配置列表
configlist_marker = '/* End XCConfigurationList section */'
new_config_list = f"""\t\t{ids['widget_config_list']} /* Build configuration list for PBXNativeTarget "LxMusicWidget" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{ids['widget_config_debug']} /* Debug */,
\t\t\t\t{ids['widget_config_release']} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
{configlist_marker}"""
content = content.replace(configlist_marker, new_config_list)

# 12. 把 Widget target 加到 PBXProject 的 targets 列表
# 找 targets = ( 后面加
content = content.replace(
    'targets = (\n\t\t\t\t13B07F861A680F5B00A75B9A /* LxMusicMobile */,\n\t\t\t);',
    f'targets = (\n\t\t\t\t13B07F861A680F5B00A75B9A /* LxMusicMobile */,\n\t\t\t\t{ids["widget_target"]} /* LxMusicWidget */,\n\t\t\t);'
)

with open(pbx_path, 'w') as f:
    f.write(content)

print("✅ pbxproj 修改完成！")
print(f"Widget target UUID: {ids['widget_target']}")
