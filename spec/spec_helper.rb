class ApplicationController
end

module ActionController
  module Caching
    class Sweeper
    end
  end
end


require 'varnish_sweeper'
require 'rspec'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end
