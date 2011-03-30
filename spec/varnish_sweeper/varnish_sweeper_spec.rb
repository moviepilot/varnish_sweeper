require File.dirname(__FILE__) + '/../spec_helper'

describe "VarnishSweeper" do
#  it "should provide our functions to the ApplicationController" do
#    ApplicationController.new.should respond_to(:make_cacheable)
#    ApplicationController.new.should respond_to(:sweep_cache_for)
#  end
#
#  it "should provide our functions to the ActionController::Caching::Sweeper" do
#    ActionController::Caching::Sweeper.new.should respond_to(:make_cacheable)
#    ActionController::Caching::Sweeper.new.should respond_to(:sweep_cache_for)
#  end

  it "should make the sweeper job available" do
    defined?(SweeperJob).should_not be_nil
  end
end
