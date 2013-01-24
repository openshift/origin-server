require File.expand_path('../../test_helper', __FILE__)


class ScalingControllerTest < ActionController::TestCase

  uses_http_mock :sometimes

  def mock_domain
    {:id => 'test'}
  end
  def app_without_scaling
    {:name => 'test', :framework => 'php-5.3', :git_url => 'ssh://foo@bar-domain.rhcloud.com/~/something/repo.git'}
  end
  def app_with_scaling
    {:name => 'test', :framework => 'php-5.3', :git_url => 'ssh://foo@bar-domain.rhcloud.com/~/something/repo.git', :scale => true}
  end

  def cartridges_without_scaling
    [
      {:name => 'php-5.3', :current_scale => 1, :scales_from => 1, :scales_to => 1},
    ]
  end
  def cartridges_with_scaling(multiplier)
    [
      {:name => 'php-5.3', :collocated_with => ['extra-1.0', 'haproxy-1.4'], :scales_from => 1, :scales_to => multiplier*2, :current_scale => multiplier},
      {:name => 'extra-1.0', :collocated_with => ['php-5.3', 'haproxy-1.4'], :scales_from => 1, :scales_to => 1, :current_scale => 1},
      {:name => 'haproxy-1.4', :collocated_with => ['php-5.3', 'extra-1.0'], :scales_from => 1, :scales_to => 1, :current_scale => 1},
      {:name => 'mysql-5.0', :scales_from => 1, :scales_to => 1, :current_scale => 1},
    ]
  end

  def with_mock_app(app=app_without_scaling, cartridges=cartridges_without_scaling)
    with_unique_user

    allow_http_mock
    ActiveResource::HttpMock.respond_to(false) do |mock|
      mock.get '/broker/rest/cartridges.json', anonymous_json_header, [].to_json
      mock.get '/broker/rest/user.json', json_header, {:max_gears => 16}.to_json
      mock.get '/broker/rest/domains.json', json_header, [mock_domain].to_json
      mock.get '/broker/rest/domains/test/applications/test.json', json_header, app.to_json
      mock.get '/broker/rest/domains/test/applications.json', json_header, [app].compact.to_json
      mock.get '/broker/rest/domains/test/applications/test/cartridges.json', json_header, cartridges.to_json
    end
    {:application_id => 'test'}
  end

  def without_scaling
    with_unique_user
    with_mock_app
  end
  def with_scaling(multiplier=1)
    with_unique_user
    with_mock_app(app_with_scaling, cartridges_with_scaling(multiplier))
  end

  test 'displays form and title for scaling' do
    get :show, with_scaling(2)
    assert_select 'h2', "php-5.3"
    assert_select 'h2', "extra-1.0"
    assert_select 'h2', "mysql-5.0"
  end

  def scalable_app_params
    {
      :application_id => with_scalable_app.to_param,
      :id => scalable_cartridge.name
    }
  end
  def scalable_cartridge
    with_scalable_app.cartridges.find(&:scales?)
  end
  def assert_cart_scales(from, to, message='Cartridge scaling not set correctly')
    scalable_cartridge.reload.tap{ |c| assert_equal [from,to], [c.scales_from, c.scales_to], message }
  end

  test 'updates scale range' do
    put :update, {:cartridge => {:scales_from => 2, :scales_to => 3}}.merge(scalable_app_params)
    assert_redirected_to application_scaling_path
    assert_cart_scales 2, 3
  end

  test 'allows fixed scale range' do
    put :update, {:cartridge => {:scales_from => 3, :scales_to => 3}}.merge(scalable_app_params)
    assert_redirected_to application_scaling_path, assigns(:cartridge).errors.inspect
    assert_cart_scales 3, 3
  end

  test 'allows unlimited scale range' do
    put :update, {:cartridge => {:scales_from => 3, :scales_to => -1}}.merge(scalable_app_params)
    assert_redirected_to application_scaling_path, assigns(:cartridge).errors.inspect
    assert_cart_scales 3, -1
  end

  test 'flips scale range if necessary' do
    put :update, {:cartridge => {:scales_from => 3, :scales_to => 2}}.merge(scalable_app_params)
    assert_redirected_to application_scaling_path
    assert_equal [2, 3], [assigns(:cartridge).scales_from, assigns(:cartridge).scales_to]
    assert_cart_scales 2, 3
  end

  test 'rejects unlimited scales_from' do
    put :update, {:cartridge => {:scales_from => -1, :scales_to => 2}}.merge(scalable_app_params)
    assert_response :success
    assert_select 'ul.alert-error > li', "Invalid scales_(from|to) factor -1 provided"
  end

  test 'rejects out of range scales_from' do
    if scalable_cartridge.supported_scales_from > 0
      put :update, {:cartridge => {:scales_from => 0, :scales_to => 2}}.merge(scalable_app_params)
      assert_response :success
      assert_select 'ul.alert-error > li', "Invalid scales_(from|to) factor 0 provided"
    else
      fail 'Test case needs to be updated, a cart can be scaled to 0 now'
    end
  end

  test 'rejects impossible scales_to' do
    put :update, {:cartridge => {:scales_from => 2, :scales_to => -2}}.merge(scalable_app_params)
    assert_response :success
    assert_select 'ul.alert-error > li', "Invalid scales_(from|to) factor -2 provided"
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
      get :new, mock ? without_scaling : {:application_id => with_app.to_param}
      assert app = assigns(:application)
      assert assigns(:domain)
      assert_response :success
    end

    test "should show if all components exist #{'(mock)' if mock}" do
      get :show, mock ? with_scaling : {:application_id => with_scalable_app.to_param}
      assert app = assigns(:application), @response.pretty_inspect
      assert app.ssh_string
      assert assigns(:domain)
      assert_response :success
    end
  end
end
