# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

require 'rbk/version'


Gem::Specification.new do |s|
  s.name        = 'rbk'
  s.version     = Rbk::VERSION.dup
  s.authors     = ['Mathias Söderberg']
  s.email       = ['mths@sdrbrg.se']
  s.homepage    = 'https://github.com/mthssdrbrg/rbk'
  s.summary     = 'Clones and uploads GitHub repos belonging to an organization'
  s.description = 'GitHub repo backup utility'
  s.license     = 'BSD-3-Clause'

  s.files         = Dir['lib/**/*.rb', 'README.md']
  s.test_files    = Dir['spec/**/*.rb']
  s.executables   = %w[rbk]

  s.add_dependency 'aws-sdk-v1', '~> 1.64'
  s.add_dependency 'github_api', '~> 0.12'
  s.add_dependency 'git', '~> 1.2'

  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.3'
end
