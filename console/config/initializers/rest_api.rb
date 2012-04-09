module RestApi
  CONFIGURATIONS = {
    :openshift => {
      :url => 'https://openshift.redhat.com/broker/rest',
      #:ssl_options => {},
      #:proxy => '',
      :authentication => :passthrough
    },
    :local => {
      :url => 'https://localhost/broker/rest'
    }
  }

  def self.activate_configuration(config=nil)
    return if config == :none
    config ||= :local
    symbol = config if config.is_a? Symbol
    config = (CONFIGURATIONS[config] || symbol) if symbol

    unless config && defined? config[:url]
      raise <<-EXCEPTION

RestApi requires that Rails.configuration.broker be set to a symbol or broker configuration object.  Active configuration is #{Rails.env}

'#{config.inspect}' is not valid.

Valid symbols: #{RestApi::CONFIGURATIONS.each_key.collect {|k| ":#{k}"}.join(', ')}
Valid broker object:
  {
    :url => '' # A URL pointing to the root of the REST API, e.g. 
               # https://openshift.redhat.com/broker/rest
  }
      EXCEPTION
    end

    url = URI.parse(config[:url])
    prefix = url.path
    prefix = "#{prefix}/" unless prefix[-1..1]

    RestApi::Base.site = url.to_s
    RestApi::Base.prefix = prefix

    @config = config
    @symbol = symbol
    @info = false

    info = RestApi.info
    Rails.logger.info "Connected to #{info.url} with version #{info.version}"
  end
end

RestApi.activate_configuration(Rails.application.config.stickshift)
