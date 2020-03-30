Pod::Spec.new do |spec|
  spec.name           = "Matft"
  spec.version        = "0.1.0"
  spec.summary        = "Numpy-like matrix operation library in swift"
  spec.homepage       = "https://github.com/jjjkkkjjj/Matft"
  spec.license        = { :type => 'BSD-3-Clause', :file => 'LICENSE' }
  spec.author         = "jjjkkkjjj"
  spec.platform       = :ios, "10.0"
  spec.swift_versions = "4.0"
  spec.pod_target_xcconfig  = { 'SWIFT_VERSION' => '4.0' }
  spec.source         = { :git => "https://github.com/jjjkkkjjj/Matft.git", :tag => "#{spec.version}" }
  spec.source_files   = "Sources/**/*"
end

