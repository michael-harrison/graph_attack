# frozen_string_literal: true

require 'bundler/setup'
require 'fakeredis/rspec'
require 'graph_attack'

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each {|f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
end
