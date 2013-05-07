require 'rubygems'

# puts $LOADED_FEATURES.select {|feature| feature.include?("github")}
require 'simplecov'
SimpleCov.start  do
  add_filter "/spec/"
  add_filter "/internal/"
  add_group "Controllers", "app/controllers"
  add_group "Streamworker", "lib/streamworker/"
  add_group "Config", "config"
end

require 'bundler'

require 'rails'
Bundler.require :default, :test


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
