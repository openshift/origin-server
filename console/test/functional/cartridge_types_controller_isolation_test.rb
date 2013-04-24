require File.expand_path('../../test_helper', __FILE__)

class CartridgeTypesIsolationControllerTest < ActionController::TestCase
  tests CartridgeTypesController

  uses_http_mock :sometimes

  setup :with_unique_user

  def domain
    {:id => 'test'}
  end
  def app(with_carts=false)
    {:name => 'test', :framework => 'php-5.3'}.tap do |o|
      o[:cartridges] = [{:name => 'php-5.3'}] if with_carts
    end
  end

  def mock_app
    Rails.cache.clear # cart metadata is mocked
    allow_http_mock
    ActiveResource::HttpMock.respond_to({},true) do |mock|
      mock.get '/broker/rest/domains.json', json_header, [domain].to_json
      mock.get '/broker/rest/domains/test/applications/test.json', json_header, app.to_json
      mock.get '/broker/rest/domains/test/applications/test.json?include=cartridges', json_header, app(true).to_json
      mock.get '/broker/rest/cartridges.json', anonymous_json_header, [{:name => 'fake-cart-1', :type => :embedded}].to_json
      mock.get '/broker/rest/environment.json', anonymous_json_header, {:external_cartridges_enabled => true}.to_json
    end
    app
  end

  test "should list a new server cart with no metadata" do
    mock_app
    get :index, :application_id => 'test'
    assert_response :success

    assert a = assigns(:application)
    assert_equal app[:name], a.name
    assert d = assigns(:domain)
    assert_equal domain[:id], d.id

    assert types = assigns(:installed)
    assert_equal 0, types.length
    assert types = assigns(:conflicts)
    assert_equal 0, types.length
    assert types = assigns(:requires)
    assert types.length == 0
    assert types = assigns(:blacklist)
    assert types.length == 0
    assert types = assigns(:carts)
    assert types.length > 0

    cached = CartridgeType.cached.all
    assert cached.all? {|t| (t.tags & [:installed, :inactive, 'inactive']).empty? }, cached.pretty_inspect
  end

  test "should not show a new server cart with no metadata" do
    mock_app
    get :show, :application_id => 'test', :id => 'fake_cart_1'
    assert_response :success

    assert a = assigns(:application)
    assert_equal app[:name], a.name
    assert d = assigns(:domain)
    assert_equal domain[:id], d.id

    assert_nil assigns(:cartridge_type)
    assert_not_found_page(/Cartridge Type 'fake_cart_1' does not exist/)
  end

  test "should show a new server cart with no metadata" do
    mock_app
    get :show, :application_id => 'test', :id => 'fake-cart-1'
    assert_response :success

    assert a = assigns(:application)
    assert_equal app[:name], a.name
    assert d = assigns(:domain)
    assert_equal domain[:id], d.id

    assert cart = assigns(:cartridge_type)
    assert_equal 'fake-cart-1', cart.name
  end
end
