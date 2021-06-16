# frozen_string_literal: true

require 'simplecov'
require 'codecov'
SimpleCov.start do
  add_filter '/spec/'
end

SimpleCov.minimum_coverage 95
SimpleCov.formatter = SimpleCov::Formatter::Codecov if ENV['TRAVIS']

require 'bundler/setup'
require 'smartcar'
require 'webmock/rspec'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  ENV['MODE'] = 'test'
  ENV['E2E_SMARTCAR_REDIRECT_URI'] = 'https://example.com/auth'
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec::Matchers.define :be_boolean do
  match do |actual|
    [true, false].include? actual
  end
end

WebMock.allow_net_connect!
