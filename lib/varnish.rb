module Varnish
  extend self

  def make_cacheable(options = {})
    if should_be_cached?(options)
      headers['Cache-Control'] = cache_control_text(options)
    end

    if options[:depends_on] && request.headers['X_VARNISH']
      remember_url_for_obj(request.url, options)
    end
  end

  def sweep_cache_for(obj, options = {})
    return unless obj
    urls = []

    if cache_data = Rails.cache.read( varnish_cache_key(obj))
      Rails.cache.delete( varnish_cache_key(obj) )
      urls += cache_data[:urls].to_a # .to_a: to prevent nil
    end

    if options[:urls]
      urls += options[:urls]
    end

    # removing duplicates before sweeping to reduce unnecessary overhead
    urls.uniq!

    # Sweep 'em
    sweep_urls urls, options[:instant]

    # always return urls array
    urls
  end

  def sweep_urls(urls, instant = false)
    return SweeperJob.perform(urls) if instant
    Resque.enqueue(SweeperJob, urls)
  end

  protected

  def cache_control_text(options)
    return unless should_be_cached?(options)

    string_array = []
    string_array << (options[:private] ? "private" : "public")

    string_array << "max-age=%d"  % options[:max_age].to_i   if options[:max_age]
    string_array << "s-maxage=%d" % options[:s_max_age].to_i if options[:s_max_age]

    string_array.join(", ")
  end


  def remember_url_for_obj(url, options = {})
    obj = options[:depends_on]
    cache_key = varnish_cache_key(obj)
    current_time = Time.now

    expire_times = [current_time]
    expire_times << current_time + options[:max_age]   if options[:max_age]
    expire_times << current_time + options[:s_max_age] if options[:s_max_age]

    cached_urls_for_obj = [url]
    cached_data = Rails.cache.read(cache_key)
    if cached_data
      expire_times << cached_data[:expires_at]
      cached_urls_for_obj = cached_urls_for_obj + cached_data[:urls]
    end

    # EXPIRE THIS BEAST AT SOME POINT OF TIME
    Rails.cache.write( cache_key,
                      {:expires_at => expire_times.max, :urls => cached_urls_for_obj.uniq},
                      :expires_in => (expire_times.max - Time.now).to_i )
  end

  def should_be_cached?(options)
    request.headers['X_VARNISH'] && ( options[:max_age] || options[:s_max_age] )
  end

  def varnish_cache_key(obj)
    "varnish_cw_#{obj.class_name}_#{obj.hash}"
  end

end

