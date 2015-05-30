# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

require 'rbk/version'


Gem::Specification.new do |s|
  s.name          = 'rbk'
  s.version       = Rbk::VERSION.dup
  s.authors       = ['Mathias Söderberg']
  s.email         = ['mths@sdrbrg.se']
  s.homepage      = 'https://github.com/mthssdrbrg/rbk'
  s.description   = 'Clones and uploads an organization\'s GitHub repositories to S3'
  s.summary       = 'GitHub repo backup utility'
  s.license       = 'BSD-3-Clause'
  s.bindir        = 'bin'
  s.files         = Dir['lib/**/*.rb', 'bin/*', 'README.md', 'LICENSE.txt']
  s.executables   = %w[rbk]
  s.require_paths = %w[lib]

  s.add_runtime_dependency 'aws-sdk-v1', '~> 1.64'
  s.add_runtime_dependency 'github_api', '~> 0.11', '< 0.12'
  s.add_runtime_dependency 'git', '~> 1.2'

  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.3'
end
