ENV['RACK_ENV'] = "test"
ENV['NODE_ENROLL_SECRET'] = "valid_test"

require 'rspec'
require 'rack/test'
require 'capybara/rspec'
require 'database_cleaner'
require_relative '../server.rb'

RSpec.configure do |config|
  config.before(:each) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

Capybara.app = Sinatra::Application
