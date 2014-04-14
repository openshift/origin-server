ENV["TEST_NAME"] = "functional_oauth_controller_test"

require 'test_helper'
class OauthControllerTest < ActionController::TestCase

  def setup
    @request.env['HTTP_ACCEPT'] = "application/json"

    @controller = allow_multiple_execution(OauthController.new)

    @clients = {
      :my_sso_client_id => {
        :id => :my_sso_client_id,
        :type => 'confidential',
        :secrets => ["secret1", "secret2"],
        :name => "My SSO Client",
        :redirect_uris => ["https://www.example.com/1", "https://www.example.com/2"],
        :scopes => 'read userinfo',
        :is_sso => true
      }.with_indifferent_access,

      :my_client_id => {
        :id => :my_client_id,
        :type => 'confidential',
        :secrets => ["secret3", "secret4"],
        :name => "My Regular Client",
        :redirect_uris => ["https://www.example.com/3", "https://www.example.com/4"],
        :scopes => 'read userinfo',
        :is_sso => false
      }.with_indifferent_access
    }.with_indifferent_access

    Rails.configuration.expects(:oauth_clients).at_least(0).returns(@clients)

    @login = "user#{rand(1000000000)}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.save
    register_user(@login, @password)
  end


  #
  # HTTP methods
  #
  test "access_token disallows get" do
    with_token('oauthaccesstoken', 'my_sso_client_id', false)
    get :access_token, access_token_params('my_sso_client_id', @auth.token)
    assert_response :bad_request
    assert_oauth_error 'invalid_request', 'POST'
  end

  #
  # authorize auth
  #

  test "authorize requires authorization" do
    get :authorize
    assert_response :unauthorized
  end

  test "authorize forbids token without create_authorization" do
    with_token('userinfo')
    get :authorize, authorize_params
    assert_response :forbidden
  end

  test "authorize allows token with create_authorization" do
    with_token('session')
    get :authorize, authorize_params
    assert_response :found
    assert response.location.start_with?(authorize_params[:redirect_uri])
  end

  test "authorize allows basic auth" do
    with_basic_auth
    get :authorize, authorize_params
    assert_response :found
    assert response.location.start_with?(authorize_params[:redirect_uri])
  end

  #
  # access_token auth
  #
  test "access_token requires authorization" do
    post :access_token
    assert_response :unauthorized
    assert response.body["HTTP Basic: Access denied"]
  end

  test "access_token forbids code without create_oauth_access_token" do
    with_token('userinfo', 'my_sso_client_id', false)
    post :access_token, access_token_params('my_sso_client_id', @auth.token)
    assert_response :forbidden
    assert_oauth_error 'unauthorized_client', 'not allowed'
  end

  test "access_token allows token with create_oauth_access_token" do
    with_token('oauthaccesstoken', 'my_sso_client_id', false)
    post :access_token, access_token_params('my_sso_client_id', @auth.token)
    assert_response :success
  end

  test "access_token allows access via body params" do
    with_token('oauthaccesstoken', 'my_sso_client_id', false)
    post :access_token, access_token_params('my_sso_client_id', @auth.token)
    assert_response :success
  end

  test "access_token allows client_id and client_secret to be passed via basic auth" do
    with_token('oauthaccesstoken', 'my_sso_client_id', false)

    params = access_token_params('my_sso_client_id', @auth.token)
    with_basic_auth(params.delete(:client_id), params.delete(:client_secret), false)

    post :access_token, params
    assert_response :success
  end

  test "access_token responds correctly to malformed basic auth header" do
    with_token('oauthaccesstoken', 'my_sso_client_id', false)

    params = access_token_params('my_sso_client_id', @auth.token)
    params.delete(:client_id)
    params.delete(:client_secret)
    @request.env['HTTP_AUTHORIZATION'] = "Basic malformed"

    post :access_token, params
    assert_response :bad_request
    assert_oauth_error 'invalid_request', p
  end

  test "access_token ignores basic auth if invalid bearer code is provided as param" do
    with_basic_auth
    post :access_token, access_token_params('my_sso_client_id', "bogus code")
    assert_response :unauthorized
    assert response.body["HTTP Bearer: Access denied"]
  end

  #
  # Required params
  #
  [:client_id, :redirect_uri].each do |p|
    test "authorize requires #{p} parameter or fails" do
      with_basic_auth
      get :authorize, authorize_params.tap {|h| h.delete(p) }
      assert_response :bad_request
      assert_oauth_error 'invalid_request', p
    end
  end

  [:response_type].each do |p|
    test "authorize requires #{p} parameter or redirects with error" do
      with_basic_auth
      get :authorize, authorize_params.tap {|h| h.delete(p) }
      assert_redirect_error 'invalid_request', p
    end
  end

  [:client_id, :client_secret, :grant_type].each do |p|
    test "access_token requires #{p} parameter" do
      with_token('oauthaccesstoken', 'my_sso_client_id', false)
      post :access_token, access_token_params('my_sso_client_id', @auth.token).tap {|h| h.delete(p) }
      assert_response :bad_request
      assert_oauth_error 'invalid_request', p
    end
  end

  #
  # Authorize validates client_id, redirect_uri
  #
  test "authorize validates client_id exists" do
    with_basic_auth
    get :authorize, authorize_params.merge(:client_id => "X")
    assert_response :bad_request
    assert_oauth_error 'invalid_client'
  end

  test "authorize validates response_type" do
    with_basic_auth
    get :authorize, authorize_params.merge(:response_type => "X")
    assert_redirect_error 'unsupported_response_type', 'code'
  end

  test "authorize validates redirect_uri is allowed for client" do
    with_basic_auth
    get :authorize, authorize_params.merge(:redirect_uri => "https://www.foo.com")
    assert_response :bad_request
    assert_oauth_error 'invalid_request', 'redirect_uri'
  end

  #
  # access_token validates client_id, client_secret, grant_type
  #

  test "access_token validates client_id exists" do
    with_token('oauthaccesstoken', 'my_sso_client_id', false)
    post :access_token, access_token_params('my_sso_client_id', @auth.token).merge(:client_id => "X")
    assert_response :bad_request
    assert_oauth_error 'invalid_client'
  end

  test "access_token validates grant_type" do
    with_token('oauthaccesstoken', 'my_sso_client_id', false)
    post :access_token, access_token_params('my_sso_client_id', @auth.token).merge(:grant_type => "X")
    assert_response :bad_request
    assert_oauth_error 'unsupported_grant_type', 'authorization_code'
  end

  test "access_token validates client_id matches code" do
    with_token('oauthaccesstoken', 'my_sso_client_id', false)
    post :access_token, access_token_params('my_client_id', @auth.token)
    assert_response :unauthorized
    assert_oauth_error 'unauthorized_client', 'code'
  end  

  test "access_token validates client_secret matches client_id" do
    with_token('oauthaccesstoken', 'my_sso_client_id', false)
    post :access_token, access_token_params('my_sso_client_id', @auth.token).merge(:client_secret => "X")
    assert_response :unauthorized
    assert_oauth_error 'unauthorized_client', 'client_secret'
  end

  #
  # Complete usage flows for regular and sso clients
  #
  ['my_sso_client_id', 'my_client_id'].each do |client_id|
    test "complete flow for #{client_id}" do
      client = @clients[client_id]
      expected_scopes = Scope.list!("#{client[:scopes]} #{'sso' if client[:is_sso]}")

      # Get an authorization code
      with_token('session')
      get :authorize, authorize_params(client_id).merge(:state => "test_state")
      assert_response :found
      assert response.location.start_with?(authorize_params(client_id)[:redirect_uri]), "Incorrect prefix in #{response.location}"
      assert params = Rack::Utils.parse_query(URI(response.location).query), "No params in #{response.location}"
      assert authorization_code = params['code'].presence, "No code in #{response.location}"
      assert_equal "test_state", params['state'], "State param was not echoed"

      # Validate the temporary code we got
      assert temp_auth = Authorization.authenticate(authorization_code)
      assert_equal client_id, temp_auth.oauth_client_id
      assert temp_auth.note[client[:name]], "Temporary authorization code note does not include client name"
      assert temp_auth.expires_in <= 10.minutes, "Temporary authorization code should not be longer than 10 minutes"

      # Exchange for an access_token
      post :access_token, access_token_params(client_id, authorization_code)
      assert_response :success
      assert json = JSON.parse(response.body)
      assert_equal "Bearer", json['token_type']
      assert access_token = json['access_token']
      assert_equal expected_scopes.default_expiration, json['expires_in']

      # Ensure the temp auth code is deleted
      assert_equal nil, Authorization.authenticate(authorization_code), "Temporary code was not deleted"

      # Validate the access_token we got
      assert auth = Authorization.authenticate(access_token)
      assert_equal client_id, auth.oauth_client_id
      assert_equal expected_scopes.to_s, auth.scopes
      assert_equal expected_scopes.default_expiration, auth.expires_in
      assert auth.note[client[:name]], "Authorization note does not include client name"
    end
  end


  private

    def assert_redirect_error(error, description_substring=nil)
      assert_response :found
      assert params = Rack::Utils.parse_query(URI(response.location).query), "No params in #{response.location}"
      assert_equal error, params['error']
      if description_substring.present?
        assert params['error_description']
        assert params['error_description'][description_substring.to_s], "Description didn't contain #{description_substring}: #{response.location}"
      end
    end

    def assert_oauth_error(error, description_substring=nil)
      assert json = JSON.parse(response.body)
      assert_equal error, json['error']
      if description_substring.present?
        assert json['error_description']
        assert json['error_description'][description_substring.to_s], "Description didn't contain #{description_substring}: #{response.body}"
      end
    end

    def authorize_params(client_id='my_sso_client_id')
      {
        :client_id => client_id,
        :redirect_uri => @clients[client_id][:redirect_uris].first,
        :state => "mystate",
        :response_type => "code"
      }
    end

    def access_token_params(client_id, code)
      {
        :client_id => client_id,
        :client_secret => @clients[client_id][:secrets].first,
        :code => code,
        :grant_type => "authorization_code"
      }
    end

    def with_basic_auth(login=@login, password=@password, set_remote_user=true)
      @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{login}:#{password}")
      @request.env['REMOTE_USER'] = @login if set_remote_user
    end

    def with_token(scopes, client_id=nil, set_header=true)
      s = Scope.list!(scopes)
      @auth = Authorization.create!({
        :expires_in => s.default_expiration
      }) do |a|
        a.user = @user
        a.scopes = s.to_s
        a.oauth_client_id = client_id if client_id
      end
      @request.env['HTTP_AUTHORIZATION'] = "Bearer #{@auth.token}" if set_header
      @auth.token
    end  
end
