# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/xcresult_to_junit/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-xcresult_to_junit'
  spec.version       = Fastlane::XcresultToJunit::VERSION
  spec.author        = 'Shane Birdsall'
  spec.email         = 'shane.birdsall@fiserv.com'

  spec.summary       = 'Produces junit xml files from Xcode 11+ xcresult files'
  spec.homepage      = "https://github.com/zanizrules/fastlane-plugin-xcresult_to_junit"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  # spec.add_dependency 'your-dependency', '~> 1.0.0'

  spec.add_development_dependency('pry')
  spec.add_development_dependency('bundler')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rspec_junit_formatter')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rubocop', '0.49.1')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('simplecov')
end
