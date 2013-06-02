# encoding: utf-8
require "bundler/setup"

ENV['MOCK'] ||= 'on'
require "pry"
require 'growthforecast-client'
require 'webmock/rspec'
require 'cgi'
WebMock.allow_net_connect! if ENV['MOCK'] == 'off'

ROOT = File.dirname(__FILE__)
Dir[File.expand_path("support/**/*.rb", ROOT)].each {|f| require f }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
end

def u(str)
  ::CGI.unescape(str.gsub('%20', '+')) if str
end

def e(str)
  ::CGI.escape(str).gsub('+', '%20') if str
end

def base_uri
  'http://localhost:5125'
end

def client
  GrowthForecast::Client.new(base_uri)
end

