require 'varnish'
ApplicationController.send(:include, Varnish)
ActionController::Caching::Sweeper.send(:include, Varnish)
require 'sweeper_job'
