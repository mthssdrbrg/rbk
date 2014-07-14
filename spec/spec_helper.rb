# encoding: utf-8

FakeRepo = Struct.new(:name, :ssh_url)

require 'simplecov'

SimpleCov.start do
  add_group 'Source', 'lib'
  add_group 'Unit tests', 'spec/rbk'
  add_group 'Acceptance tests', 'spec/acceptance'
end

RSpec.configure do |config|
  config.order = 'random'
end

require 'rbk'
