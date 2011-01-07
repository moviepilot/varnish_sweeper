require 'resque-loner'

class SweeperJob < Resque::Plugins::Loner::UniqueJob
  @queue = :sweeper

  def self.perform( urls, options = {} )
    if urls
      urls.each do |url|
        Curl::Easy.perform(url) do |curl| 
          curl.headers["X-Varnish-Control"] = "sweep"
        end
        Rails.logger.debug "sweeped #{url}"
      end
    end
  end
end
