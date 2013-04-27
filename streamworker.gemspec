$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "streamworker/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "streamworker"
  s.version     = Streamworker::VERSION
  s.authors     = ["Michael Johnston"]
  s.email       = ["opensource@lastobelus.com"]
  s.homepage    = "https://github.com/lastobelus/streamworker"
  s.summary     = "Rails Engine that provides workers implemented as http streaming requests."
  s.description = "Rails Engine that provides workers implemented as http streaming requests."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2"
  # s.add_dependency "jquery-rails"
  s.add_dependency "unicorn"
  s.add_dependency "slim", ">= 2.0.0.pre.8"

  s.add_development_dependency "sqlite3"
end
