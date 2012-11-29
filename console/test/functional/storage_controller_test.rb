require File.expand_path('../../test_helper', __FILE__)

class StorageControllerTest < ActionController::TestCase
  uses_http_mock :sometimes

  def mock_domain
    {:id => 'test'}
  end

  def mock_app
    {
      :name => 'test',
      :framework => 'php-5.3', :git_url => 'ssh://foo@bar-domain.rhcloud.com/~/something/repo.git'}
  end

  def mock_user(storage = 0)
    {
      :max_storage_per_gear => storage
    }
  end

  def mock_groups
    [
      {
        :name => '@@app/comp-web/php-5.3',
        :uuid => 1,
        :gears => [ {:id => 1, :state => 'started'} ],
        :cartridges => [ {:name => 'php-5.3'}, ]
      }
    ]
  end

  def mock_resources
    {:name => 'php-5.3', :additional_gear_storage => 1 }
  end

  def with_mock_app(storage = 0)
    allow_http_mock

    User.any_instance.stubs(:max_storage_per_gear).returns(storage)

    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.get '/broker/rest/user.json', json_header, mock_user(storage).to_json
      mock.get '/broker/rest/cartridges.json', anonymous_json_header, [].to_json
      mock.get '/broker/rest/domains.json', json_header, [mock_domain].to_json
      mock.get '/broker/rest/domains/test/applications/test.json', json_header, mock_app.to_json
      mock.get '/broker/rest/domains/test/applications.json', json_header, [mock_app].to_json
      mock.get '/broker/rest/domains/test/applications/test/cartridges.json', json_header, [mock_resources].to_json
      mock.get '/broker/rest/domains/test/applications/test/gear_groups.json', json_header, mock_groups.to_json
    end
    {:application_id => 'test'}
  end

  def storage_app_params
    {
      :application_id => with_storage_app.to_param,
      :id => with_storage_app.cartridges.first.name
    }
  end

  [true,false].each do |mock|
    test "should get redirected from show without scaling #{'(mock)' if mock}" do
      with_unique_user

      get :show, mock ? with_mock_app : {:application_id => with_app.to_param}

      assert app = assigns(:application)
      assert_redirected_to new_application_storage_path(app)
    end

    test "should show storage page#{' (mock)' if mock}" do
      with_user_with_extra_storage

      get :show, mock ? with_mock_app(10) : {:application_id => with_storage_app.to_param}

      assert_response :success
    end
  end
end
