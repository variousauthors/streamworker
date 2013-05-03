require 'rails'

module Streamworker
  class Engine < ::Rails::Engine
    isolate_namespace Streamworker
  end
end
