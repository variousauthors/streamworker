require 'rubygems'
require 'bundler'

require 'rails'
Bundler.require :default, :test

require 'simplecov'
SimpleCov.start.inspect

require 'capybara/rspec'
require 'be_valid_asset'

Combustion.initialize! :active_record, :action_controller, :action_view, :sprockets do
  require 'slim'
end

require 'rspec/rails'
require 'capybara/rails'

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f|  require f}

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
