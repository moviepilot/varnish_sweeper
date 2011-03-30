require 'rubygems'
require 'rspec'
require 'rack'
require 'ostruct'
require "active_support"
require 'varnish_sweeper'

class ApplicationController
  include Varnish

  def headers
    @headers ||= {}
  end

  def request
    @request ||= OpenStruct.new(:headers => {})
  end

end

class Rails

  def self.cache
    @@cache ||= ActiveSupport::Cache::MemoryStore.new
  end

end