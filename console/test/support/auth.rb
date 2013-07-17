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
    def persisted?
      true
    end
  end
end

module RestApiAuth
  def new_user(opts=nil)
    Test::WebUser.new opts
  end
  def new_named_user(name)
    new_user(:login => name, :password => 'foo')
  end

  #
  # Integration tests are designed to run against the 
  # production OpenShift service by default.  To change
  # this, update ~/.openshift/api.yaml to point to a
  # different server.
  #
  def with_configured_user
    config = Console.config.api
    if config[:login]
      @user = new_user :login => config[:login], :password => config[:password]
    else
      @with_unique_user = true
      @user = new_user :login => "#{uuid}@test1.com", :password => 'foo'
    end
  end
  def with_unique_user
    with_configured_user
  end

  def setup_user(unique=false)
    set_user(new_user(:email_address=>"app_test1#{unique ? uuid : ''}@test1.com", :login=>"app_test1#{unique ? uuid : ''}@test1.com"))
  end

  def set_user(user)
    if @request
      @request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user.login, user.password) if user.password
      @request.cookies['rh_sso'] = user.ticket if user.ticket
      @request.env['HTTPS'] = 'on'
    end
    @user = user
  end

  def assert_current_user(user)
    assert_equal user.login, session[:login]
    assert_equal user.ticket, session[:ticket]
  end

  # 
  # Create a new, unique user
  #
  # FIXME: Reconcile with other usage
  def unique_user
    id = new_uuid
    new_user :email_address=>"app_test1#{id}@test1.com", :login=>"app_test1#{id}@test1.com"
  end

  #
  # Create and authenticate a user that is unique per test case,
  # without any session information.
  #
  def with_simple_unique_user
    @user = RestApi::Credentials.new "rest-api-test-#{uuid}@test1.com"
    @with_unique_user = true
  end
end

class ActiveSupport::TestCase
  # All tests should be able to authentictae
  include RestApiAuth
end

class ActionController::TestCase
  #
  # Functional tests are designed to run against the 
  # production OpenShift service by default.  To change
  # this, update ~/.openshift/api.yaml to point to a
  # different server.
  #
  def with_configured_user
    set_user(super)
  end

  def user_to_session(user, ses={})
    ses
  end

  def mock_controller_user(extends=nil)
    @controller.expects(:current_user).at_least(0).returns(@user)
    @user.expects(:extends).at_least(0).with(extends).returns(@user) if extends
    @user
  end
end

class ActionDispatch::IntegrationTest
  def user_can_authenticate(obj)
    assert @user.login
    @user.password ||= "arbitrary_pass"
    obj
  end
  def login
    @user_env = {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, @user.password)}
  end
  def user_env
    @user_env
  end
  #
  # Helper to reuse session cookies (and avoid login) in
  # web sessions.
  #
  def with_user_session(sym, cookie_url, &block)
    api_fetch(sym) do |cached|
      if cached
        set_user(cached[:user])
        # Get on the correct domain for setting cookies
        visit cookie_url
        cached[:cookies].each do |(name,c)|
          page.driver.remove_cookie(name)
          page.driver.set_cookie(name, c.value, {
            :path     => c.path,
            :expires  => c.expires,
            :domain   => c.domain,
            :httponly => c.httponly?,
            :secure   => c.secure?
          })
        end
        cached
      else
        yield
        { 
          :cookies => page.driver.cookies.map{ |name, c| [name, c.dup] },
          :user => @user.dup
        }
      end
    end
  end

  #
  # Start a capybara session that reuses cookies
  #
  def with_logged_in_console_user
    with_user_session(:logged_in_user_and_cookies, login_path) do
      with_unique_user
      visit_console_login
    end
  end

  #
  # Log the provided user into the console
  #
  def visit_console_login(user=@user)
    visit login_path

    assert page.has_content? "Sign in to OpenShift"
    within "#login_form" do
      fill_in 'Login', :with => user.login
      fill_in 'Password', :with => user.password
    end
    click_button 'Sign in'
  end

end