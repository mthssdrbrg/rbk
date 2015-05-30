# encoding: utf-8

FakeRepo = Struct.new(:name, :ssh_url)

RSpec.configure do |config|
  config.order = 'random'
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
