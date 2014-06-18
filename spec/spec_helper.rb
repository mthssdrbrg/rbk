# encoding: utf-8

require 'simplecov'

SimpleCov.start do
  add_group 'Source', 'lib'
  add_group 'Unit tests', 'spec/rbk'
  add_group 'Integration tests', 'spec/integration'
end

RSpec.configure do |config|
  config.order = 'random'
end

require 'rbk'
