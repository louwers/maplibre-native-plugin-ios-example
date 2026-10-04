#!/usr/bin/env ruby
require 'xcodeproj'

Dir.chdir(File.expand_path('..', __dir__))
project = Xcodeproj::Project.new('NgonExample.xcodeproj')
app = project.new_target(:application, 'NgonExample', :ios, '15.5')
tests = project.new_target(:ui_test_bundle, 'NgonExampleTests', :ios, '15.5')
tests.add_dependency(app)

app_group = project.main_group.new_group('App', 'App')
app.add_file_references([app_group.new_file('main.mm')])
app.resources_build_phase.add_file_reference(app_group.new_file('ngon.json'))
plugin_group = project.main_group.new_group('Ngon', 'Ngon')
app.add_file_references([plugin_group.new_file('shared/cpp/ngon_layer.cpp')])
plugin_group.new_file('shared/include/ngon_layer.hpp')
plugin_group.new_file('generated/ngon_shader_sources.hpp')
tests_group = project.main_group.new_group('Tests', 'Tests')
tests.add_file_references([tests_group.new_file('NgonExampleTests.swift')])
frameworks = project.main_group.new_group('Frameworks', 'Frameworks')
framework = frameworks.new_file('MapLibreWithPlugins.xcframework')
framework.last_known_file_type = 'wrapper.xcframework'
app.frameworks_build_phase.add_file_reference(framework)
['UIKit', 'CoreGraphics', 'CoreLocation'].each do |name|
  framework_ref = project.frameworks_group.new_file("System/Library/Frameworks/#{name}.framework", :sdk_root)
  app.frameworks_build_phase.add_file_reference(framework_ref)
end
# Use the selected SDK instead of the generator gem's default SDK version.
project.files.select { |file| file.path&.end_with?('Foundation.framework') }.each do |file|
  file.path = 'System/Library/Frameworks/Foundation.framework'
  file.source_tree = 'SDKROOT'
end
embed = app.new_copy_files_build_phase('Embed Frameworks')
embed.dst_subfolder_spec = '10'
embedded = embed.add_file_reference(framework)
embedded.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }

[app, tests].each do |target|
  target.build_configurations.each do |config|
    settings = config.build_settings
    settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    settings['CLANG_ENABLE_MODULES'] = 'YES'
    settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
    settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'c++20'
    settings['SWIFT_VERSION'] = '5.0'
    settings['TARGETED_DEVICE_FAMILY'] = '1,2'
    settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.5'
    settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator'
    settings['SUPPORTS_MACCATALYST'] = 'NO'
    settings['CODE_SIGN_STYLE'] = 'Automatic'
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = "org.maplibre.#{target.name}"
    settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks']
    settings['MARKETING_VERSION'] = '1.0'
    settings['CURRENT_PROJECT_VERSION'] = '1'
  end
end
app.build_configurations.each do |config|
  settings = config.build_settings
  settings['HEADER_SEARCH_PATHS'] = ['$(inherited)', '$(SRCROOT)/Support', '$(SRCROOT)/Ngon/shared/include', '$(SRCROOT)/Ngon/generated']
  settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
  settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'Ngon Plugin'
  settings['INFOPLIST_KEY_UISupportedInterfaceOrientations'] = 'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
end
tests.build_configurations.each do |config|
  config.build_settings['TEST_TARGET_NAME'] = 'NgonExample'
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(tests)
scheme.set_launch_target(app)
scheme.save_as(project.path, 'NgonExample', true)
