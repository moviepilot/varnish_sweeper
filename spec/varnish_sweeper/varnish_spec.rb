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

  describe :sweep_cache_for, "with cached url" do

    before do
      @obj = mock('Model')
      @controller.stub!(:varnish_cache_key).with(@obj).and_return("cache_key")
      @cached_urls = ["cached_url","cached_url_b"]
      @opt_urls = ["url_a","url_b","cached_url_b"]
      Rails.cache.write("cache_key", :urls => @cached_urls)
    end

    context 'asynchronous sweeping (default)' do

      it "should enqueue the sweeping job with resque" do
        Resque.should_receive(:enqueue).with(SweeperJob, @cached_urls)
        @controller.sweep_cache_for(@obj)
      end

    end

    context 'instant sweeping (with option :instant => true)' do

      it "should sweep the cache instantly" do
        SweeperJob.should_receive(:perform).with(@cached_urls)
        @controller.sweep_cache_for(@obj, :instant => true)
      end

    end
    
    context 'sweeping cached and self-defined urls (with option :urls => @opt_urls)' do
      
      it "should sweep normal cache + optional urls, :instant => true" do
        SweeperJob.should_receive(:perform).with( (@cached_urls+@opt_urls).uniq )
        @controller.sweep_cache_for(@obj, :instant => true, :urls => @opt_urls)
      end
      
      it "should sweep normal cache + optional urls, :instant => true, return value check" do
        SweeperJob.should_receive(:perform).with( (@cached_urls+@opt_urls).uniq )
        @controller.sweep_cache_for(@obj, :instant => true, :urls => @opt_urls).should == (@cached_urls+@opt_urls).uniq
      end
      
      it "should sweep normal cache + optional urls, :instant => false" do
        Resque.should_receive(:enqueue).with(SweeperJob, (@cached_urls+@opt_urls).uniq )
        @controller.sweep_cache_for(@obj, :instant => false, :urls => @opt_urls)
      end
      
      it "should sweep normal cache + optional urls, :instant => false, return value check" do
        Resque.should_receive(:enqueue).with(SweeperJob, (@cached_urls+@opt_urls).uniq )
        @controller.sweep_cache_for(@obj, :instant => false, :urls => @opt_urls).should == (@cached_urls+@opt_urls).uniq
      end
      
    end

  end
  
  describe :sweep_cache_for, "without cached url" do

    before do
      @obj = mock('Model')
      @controller.stub!(:varnish_cache_key).with(@obj).and_return("cache_key")
      @opt_urls = ["url_c","url_d"]
    end
    
    context 'sweeping self-defined urls only (with option :urls => @opt_urls)' do
      
      it "should sweep optional urls only, :instant => true" do
        SweeperJob.should_receive(:perform).with(@opt_urls)
        @controller.sweep_cache_for(@obj, :instant => true, :urls => @opt_urls)
      end
      
      it "should sweep optional urls only, :instant => true, return value check" do
        SweeperJob.should_receive(:perform).with(@opt_urls)
        @controller.sweep_cache_for(@obj, :instant => true, :urls => @opt_urls).should == @opt_urls
      end
      
      it "should sweep optional urls only, :instant => false" do
        Resque.should_receive(:enqueue).with(SweeperJob, @opt_urls)
        @controller.sweep_cache_for(@obj, :instant => false, :urls => @opt_urls)
      end
      
      it "should sweep optional urls only, :instant => false, return value check" do
        Resque.should_receive(:enqueue).with(SweeperJob, @opt_urls)
        @controller.sweep_cache_for(@obj, :instant => false, :urls => @opt_urls).should == @opt_urls
      end
      
    end

  end

end
