require File.expand_path('../../test_helper', __FILE__)

class ScalingControllerTest < ActionController::TestCase
  include ActiveSupport::Testing::Isolation

  def setup
    require 'active_resource/persistent_http_mock'
  end

  def json_header(is_post=false)
    {(is_post ? 'Content-Type' : 'Accept') => 'application/json'}.merge!(auth_headers)
  end

  def domain
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

  def with_app(app=app_without_scaling, gear_groups=groups_without_scaling)
    with_unique_user

    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.get '/broker/rest/cartridges.json', json_header, [].to_json
      mock.get '/broker/rest/domains.json', json_header, [domain].to_json
      mock.get '/broker/rest/domains/test/applications/test.json', json_header, app.to_json
      mock.get '/broker/rest/domains/test/applications.json', json_header, [app].compact.to_json
      mock.get '/broker/rest/domains/test/applications/test/gear_groups.json', json_header, gear_groups.to_json
    end
    {:application_id => 'test'}
  end

  def without_scaling
    with_unique_user
    with_app
  end
  def with_scaling(multiplier=1)
    with_unique_user
    with_app(app_with_scaling, groups_with_scaling(multiplier))
  end

  test "should get redirected from show without scaling" do
    get :show, without_scaling
    assert app = assigns(:application)
    assert assigns(:domain)
    assert_redirected_to new_application_scaling_path(app)
  end

  test "should get redirected from delete without scaling" do
    get :delete, without_scaling
    assert app = assigns(:application)
    assert assigns(:domain)
    assert_redirected_to new_application_scaling_path(app)
  end

  test "should see new page without scaling" do
    get :new, without_scaling
    assert app = assigns(:application)
    assert assigns(:domain)
    assert_response :success
  end

  test "should show if all components exist" do
    get :show, with_scaling
    assert app = assigns(:application)
    assert app.ssh_string
    assert assigns(:domain)
    assert_response :success
  end
end
