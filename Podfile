platform :ios, '13.0'

target 'NihonRyokou' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for NihonRyokou
  pod 'IQKeyboardManagerSwift', '7.1.1'
  pod 'Then'
  pod 'SnapKit'

  target 'NihonRyokouTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'NihonRyokouUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
end
