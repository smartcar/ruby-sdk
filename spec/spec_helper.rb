# frozen_string_literal: true

require 'bundler/setup'
require 'smartcar'
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  ENV['MODE'] = 'test'
  ENV['SMARTCAR_REDIRECT_URI'] = 'https://example.com/auth'
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSpec::Matchers.define :be_boolean do
  match do |actual|
    [true, false].include? actual
  end
end
