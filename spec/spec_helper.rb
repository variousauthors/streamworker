require 'rubygems'
require 'bundler'

require 'rails'
Bundler.require :default, :test

puts $LOADED_FEATURES.select {|feature| feature.include?("github")}
require 'simplecov'
SimpleCov.start 'rails'

puts "pwd: " + Dir.pwd
puts "files: " + Dir["lib/**/*.rb"].inspect
Dir["lib/**/*.rb"].each {|file| puts file; puts load(file); }
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
