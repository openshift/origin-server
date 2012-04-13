require 'active_support/configurable'

module Console

  # Configures global settings for Console
  # Console.configure do |config|
  # config.disable_assets = 10
  # end
  def self.configure(&block)
    yield config
  end

  # Global settings for Console
  def self.config
    @config ||= Configuration.new
  end

  # need a Class for 3.0
  class Configuration #:nodoc:
    include ActiveSupport::Configurable
    config_accessor :disable_css
    config_accessor :disable_js
  end

  configure do |config|
    config.disable_js = false
    config.disable_css = false
  end
end
