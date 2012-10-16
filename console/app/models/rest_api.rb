module RestApi
  #
  # An Authorization object should expose:
  #
  #  login - method returning an identifier for the user
  #
  # and one of:
  #
  #  ticket - the unique ticket for the session
  #  password - a user password
  #
  class Authorization
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
      @model.constantize rescue RestApi::Base
    end
    def domain_missing?
      @model == 'Domain' || RestApi::Base.remote_errors_for(response).any?{ |m| m[0] == 127 } rescue false
    end
    def to_s
      "#{model.to_s.titleize}#{ " '#{id}'" unless id.nil?} does not exist"
    end
  end

  # The server did not return the response we were expecting, possibly a server bug
  class BadServerResponseError < StandardError ; end

  class << self
    #
    # All code in the block will dump detailed HTTP logs
    #
    def debug(set=true,&block)
      @debug = set
      if block_given?
        begin
          yield block
        ensure
          @debug = false
        end
      end
    end
    def debug?
      @debug || ENV['REST_API_DEBUG']
    end

    #
    # Is the API reachable?
    #
    def test?
      info.present? rescue false
    end

    #
    # Return the version information about the REST API
    #
    def info
      @info ||= RestApi::Info.find :one
    rescue Exception => e
      raise ApiNotAvailable, <<-EXCEPTION, e.backtrace

The REST API could not be reached at #{RestApi::Base.site}

  Rails environment:     #{Rails.env}
  Current configuration: #{config.inspect} #{config[:symbol] ? "(via :#{config[:symbol]})" : ''}

  #{e.message}
  #{e.backtrace.join("\n  ")}
      EXCEPTION
    end

    # FIXME: May be desirable to replace this with a standard ActiveSupport config object
    def config
      RestApi::Base.instance_variable_get("@last_config") || {}
    end

    # FIXME: replace with a dynamic call to api.json
    def application_domain_suffix
      config[:suffix]
    end

    def site
      RestApi::Base.site
    end

    private
      def symbol
        RestApi::Base.instance_variable_get('@symbol')
      end
  end
end
