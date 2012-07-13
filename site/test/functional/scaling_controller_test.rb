require File.expand_path('../../test_helper', __FILE__)


class ScalingControllerTest < ActionController::TestCase

  uses_http_mock :sometimes

  def json_header(is_post=false)
    {(is_post ? 'Content-Type' : 'Accept') => 'application/json'}.merge!(auth_headers)
  end

  def mock_domain
    {:id => 'test'}
  end
  def app_without_scaling
    {:name => 'test', :framework => 'php-5.3', :git_url => 'ssh://foo@bar-domain.rhcloud.com/~/something/repo.git'}
  end
  def app_with_scaling
    {:name => 'test', :framework => 'php-5.3', :git_url => 'ssh://foo@bar-domain.rhcloud.com/~/something/repo.git', :scale => true}
  end

  def groups_without_scaling
    [
      {:name => '@@app/comp-web/php-5.3', :gears => [
        {:id => 1, :state => 'started'}
      ], :cartridges => [
        {:name => 'php-5.3'},
      ]},
    ]
  end
  def groups_with_scaling(multiplier)
    [
      {:name => '@@app/comp-web/php-5.3', 
         :gears => multiplier.times.map{ |i| {:id => i, :state => 'started'} }, 
         :cartridges => [{:name => 'php-5.3'},]},
      {:name => '@@app/comp-proxy/php-5.3', :gears => [
        {:id => 2, :state => 'started'},
      ], :cartridges => [
        {:name => 'php-5.3'},
        {:name => 'haproxy-1.4'},
      ]},
      {:name => '@@app/comp-mysql/mysql-5.0', :gears => [
        {:id => 3, :state => 'started'},
      ], :cartridges => [
        {:name => 'my-sql-5.0'},
      ]},
    ]
  end

  def with_mock_app(app=app_without_scaling, gear_groups=groups_without_scaling)
    with_unique_user

    allow_http_mock
    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, [].to_json
      mock.get '/broker/rest/domains.json', json_header, [mock_domain].to_json
      mock.get '/broker/rest/domains/test/applications/test.json', json_header, app.to_json
      mock.get '/broker/rest/domains/test/applications.json', json_header, [app].compact.to_json
      mock.get '/broker/rest/domains/test/applications/test/gear_groups.json', json_header, gear_groups.to_json
    end
    {:application_id => 'test'}
  end

  def without_scaling
    with_unique_user
    with_mock_app
  end
  def with_scaling(multiplier=1)
    with_unique_user
    with_mock_app(app_with_scaling, groups_with_scaling(multiplier))
  end

  [true, false].each do |mock|
    test "should get redirected from show without scaling #{'(mock)' if mock}" do
      get :show, mock ? without_scaling : {:application_id => with_app.to_param}
      assert app = assigns(:application)
      assert assigns(:domain)
      assert_redirected_to new_application_scaling_path(app)
    end

    test "should get redirected from delete without scaling #{'(mock)' if mock}" do
      get :delete, mock ? without_scaling : {:application_id => with_app.to_param}
      assert app = assigns(:application)
      assert assigns(:domain)
      assert_redirected_to new_application_scaling_path(app)
    end

    test "should see new page without scaling #{'(mock)' if mock}" do
      puts "Starting test #{mock} #{ActiveResource::HttpMock.enabled?}"
      get :new, mock ? without_scaling : {:application_id => with_app.to_param}
      assert app = assigns(:application)
      assert assigns(:domain)
      assert_response :success
    end

    test "should show if all components exist #{'(mock)' if mock}" do
      get :show, mock ? with_scaling : {:application_id => with_scalable_app.to_param}
      assert app = assigns(:application)
      assert app.ssh_string
      assert assigns(:domain)
      assert_response :success
    end
  end
end
