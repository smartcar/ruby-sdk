require "bundler/setup"
require "smartcar"
RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  ENV["INTEGRATION_REDIRECT_URI"] = "https://example.com/auth" if ENV["MODE"] == "test"
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
