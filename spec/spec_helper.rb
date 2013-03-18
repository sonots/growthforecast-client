# encoding: utf-8
require "bundler/setup"

ENV['MOCK'] ||= 'on'
require "pry"
require 'growthforecast-client'
require 'webmock/rspec' if ENV['MOCK'] == 'on'

ROOT = File.dirname(__FILE__)
Dir[File.expand_path("support/**/*.rb", ROOT)].each {|f| require f }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
end
