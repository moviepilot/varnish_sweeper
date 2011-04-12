require File.dirname(__FILE__) + '/../spec_helper'

describe Varnish do

  before do
    @controller = ApplicationController.new
  end

  describe :make_cachable do

    before do
      @controller.request.headers['X_VARNISH'] = 'Varnish'
    end

    it "should set the Cache-Control header to private if the option private is set" do
      @controller.make_cacheable(:private => true, :s_max_age => 3600)
      @controller.headers["Cache-Control"].should == 'private, s-maxage=3600'
    end

    it "should set the Cache-Control header to public including the given s_max_age" do
      @controller.make_cacheable(:s_max_age => 3600)
      @controller.headers["Cache-Control"].should == 'public, s-maxage=3600'
    end

    it "should set the Cache-Control header to public including the given max_age" do
      @controller.make_cacheable(:max_age => 3600)
      @controller.headers["Cache-Control"].should == 'public, max-age=3600'
    end

  end

  describe :sweep_cache_for do

    before do
      @obj = mock('Model')
      @controller.stub!(:varnish_cache_key).with(@obj).and_return("cache_key")
      Rails.cache.write("cache_key", :urls => ["cached_url"])
    end

    context 'asynchronous sweeping (default)' do

      it "should enqueue the sweeping job with resque" do
        Resque.should_receive(:enqueue).with(SweeperJob, ["cached_url"])
        @controller.sweep_cache_for(@obj)
      end

    end

    context 'instant sweeping (with option :instant => true)' do

      it "should sweep the cache instantly" do
        SweeperJob.should_receive(:perform).with(["cached_url"])
        @controller.sweep_cache_for(@obj, :instant => true)
      end

    end
    
    context 'sweeping a defined urls (with option :urls => [url,url])' do
      
      it "should sweep normal cache + optional urls" do
        SweeperJob.should_receive(:perform).with(["cached_url"]+["urla","urlb"])
        @controller.sweep_cache_for(@obj, :instant => true, :urls => ["urla","urlb"])
      end
      
      it "should sweep normal cache + optional urls" do
        Resque.should_receive(:enqueue).with(SweeperJob, ["cached_url"]+["urla","urlb"])
        @controller.sweep_cache_for(@obj, :instant => false, :urls => ["urla","urlb"])
      end
      
    end

  end
  
  describe :sweep_cache_for do

    before do
      @obj = mock('Model')
      @controller.stub!(:varnish_cache_key).with(@obj).and_return("cache_key")
    end
    
    context 'sweeping a defined urls (with option :urls => [url,url])' do
      
      it "should sweep normal cache + optional urls" do
        SweeperJob.should_receive(:perform).with(["urla","urlb"])
        @controller.sweep_cache_for(@obj, :instant => true, :urls => ["urla","urlb"])
      end
      
      it "should sweep normal cache + optional urls" do
        Resque.should_receive(:enqueue).with(SweeperJob, ["urla","urlb"])
        @controller.sweep_cache_for(@obj, :instant => false, :urls => ["urla","urlb"])
      end
      
      it "should sweep normal cache + optional urls" do
        Resque.should_receive(:enqueue).with(SweeperJob, ["urla","urlb"])
        @controller.sweep_cache_for(@obj, :instant => false, :urls => ["urla","urlb"]).should == ["urla","urlb"]
      end
      
    end

  end

end
