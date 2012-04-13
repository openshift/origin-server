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
  end

  class << self
    #
    # All code in the block will dump detailed HTTP logs
    #
    def debug(&block)
      @debug = true
      yield block
    ensure
      @debug = false
    end
    def debug?
      @debug
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
      @info ||= Info.find :one
    rescue Exception => e
      raise ApiNotAvailable, <<-EXCEPTION

The REST API could not be reached at #{RestApi::Base.site}

  Rails environment:     #{Rails.env}
  Current configuration: #{config.inspect} #{symbol ? "(via :#{symbol})" : ''}

  #{e.message}
    #{e.backtrace.join("\n    ")}
---------------------------------
      EXCEPTION
    end

    private
      def symbol
        RestApi::Base.instance_variable_get('@symbol')
      end
      def config
        RestApi::Base.instance_variable_get('@config')
      end
  end

  # An object which can return info about the REST API
  class Info < RestApi::Base
    self.element_name = 'api'
    singleton
    allow_anonymous

    schema do
      string :version, :status
    end
    def url
      self.class.site
    end
  end

  # During retrieval of info about the API, an error occurred
  class ApiNotAvailable < StandardError ; end

  # Raised when the authorization context is missing
  class MissingAuthorizationError < StandardError ; end

  # Raised when a newly created resource exists with the same unique primary key
  class ResourceExistsError < StandardError ; end

  # The server did not return the response we were expecting, possibly a server bug
  class BadServerResponseError < StandardError ; end
end
