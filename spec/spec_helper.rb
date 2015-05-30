# encoding: utf-8

require 'stringio'
require 'webmock'
require 'vcr'

require 'support/s3_server'


FakeRepo = Struct.new(:name, :ssh_url)

RSpec.configure do |config|
  config.order = 'random'
  config.raise_errors_for_deprecations!
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/support/cassettes'
  config.hook_into :webmock
  config.ignore_request do |request|
    URI(request.uri).port == 5000
  end
end

unless ENV['COVERAGE'] == 'no'
  require 'coveralls'
  require 'simplecov'

  if ENV.include?('TRAVIS')
    Coveralls.wear!
    SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  end

  SimpleCov.start do
    add_group 'Source', 'lib'
    add_group 'Unit tests', 'spec/rbk'
    add_group 'Acceptance tests', 'spec/acceptance'
  end
end

require 'rbk'
