module RestApi
  # The client API version
  API_VERSION = '1.4'

  #
  # An simple credential object exposes:
  #
  #  login - method returning an identifier for the user
  #
  # and one of:
  #
  #  ticket - the unique ticket for the session
  #  password - a user password
  #
  class Credentials
    attr_reader :login, :ticket, :password
    def initialize(login,ticket=nil,password=nil)
      @login = login
      @ticket = ticket
      @password = password
    end
    def cache_key
      login
    end
  end

  # During retrieval of info about the API, an error occurred
  class ApiNotAvailable < StandardError ; end

  # Raised when the authorization context is missing
  class MissingAuthorizationError < StandardError ; end

  # Raised when a newly created resource exists with the same unique primary key
  class ResourceExistsError < StandardError ; end

  class ResourceNotFound < ActiveResource::ResourceNotFound
    attr_reader :id
    def initialize(model, id, response=nil)
      @id, @model = id, model
      super(response)
    end
    def model
      @model.constantize rescue Base
    end
    def domain_missing?
      @model == 'Domain' || Base.remote_errors_for(response).any?{ |m| m[0] == 127 } rescue false
    end
    def to_s
      "#{model.to_s.titleize}#{ " '#{id}'" unless id.nil?} does not exist"
    end
  end

  # The server did not return the response we were expecting, possibly a server bug
  class BadServerResponseError < StandardError ; end

  #
  # All code in the block will dump detailed HTTP logs
  #
  def self.debug(set=true,&block)
    @debug = set
    if block_given?
      begin
        yield block
      ensure
        @debug = false
      end
    end
  end
  def self.debug?
    @debug || ENV['REST_API_DEBUG']
  end
  def self.force_http_debug
    unless ActiveResource::Connection.respond_to? :configure_http_with_debug
      ActiveResource::Connection.class_eval do
        def configure_http_with_debug(http)
          configure_http_without_debug(http)
          http.set_debug_output $stderr
          http
        end
        alias_method_chain :configure_http, :debug
      end
    end
  end

  #
  # Is the API reachable?
  #
  def self.test?
    info.present? rescue false
  end

  #
  # Return the version information about the REST API
  #
  def self.info
    Info.cached.find :one
  rescue Exception => e
    raise ApiNotAvailable, <<-EXCEPTION, e.backtrace

The REST API could not be reached at #{Base.site}

  Rails environment:     #{Rails.env}
  Current configuration: #{config.inspect} #{config[:symbol] ? "(via :#{config[:symbol]})" : ''}

  #{e.message}
  #{e.backtrace.join("\n  ")}
    EXCEPTION
  end

  def self.reset!
    @info = nil
  end

  # FIXME: May be desirable to replace this with a standard ActiveSupport config object
  def self.config
    Base.instance_variable_get("@last_config") || {}
  end

  def self.application_domain_suffix
    @application_domain_suffix ||= Environment.cached.find(:one).domain_suffix
  end

  #
  # Does the server support the 'url' parameter on app creation and on cartridge addition?
  #
  def self.external_cartridges_enabled?
    @external_cartridges_enabled ||= Environment.cached.find(:one).external_cartridges_enabled
  end

  def self.site
    Base.site
  end

  private
    def self.symbol
      Base.instance_variable_get('@symbol')
    end
end
