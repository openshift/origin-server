module Test
  class WebUser
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::Serialization
    extend ActiveModel::Naming

    attr_accessor :login, :password, :ticket
    def initialize(opts={})
      opts.each_pair { |key,value| send("#{key}=", value) }
      @roles = []
    end
    def email_address=(address)
      login = address
      @email_address = address
    end
    def rhhogin
      login
    end
  end
end

module RestApiAuth
  #
  # Integration tests are designed to run against the 
  # production OpenShift service by default.  To change
  # this, update ~/.openshift/api.yaml to point to a
  # different server.
  #
  def with_configured_user
    config = Console.config.api
    if config[:login]
      @user = Test::WebUser.new :login => config[:login], :password => config[:password]
    else
      @with_unique_user = true
      @user = Test::WebUser.new :login => "#{name}#{uuid}@test1.com"
    end
  end
end

class ActionController::TestCase
  # All ActionControllers should be able to authentictae
  include RestApiAuth

  #
  # Functional tests are designed to run against the 
  # production OpenShift service by default.  To change
  # this, update ~/.openshift/api.yaml to point to a
  # different server.
  #
  alias_method :with_configured_api_user, :with_configured_user
  def with_configured_user
    user = with_configured_api_user
    @controller.stubs(:authenticate_user!)
    @controller.stubs(:current_user).returns(user)
  end
end
