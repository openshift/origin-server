require File.expand_path('../../test_helper', __FILE__)

class CartridgeTypesIsolationControllerTest < ActionController::TestCase
  tests CartridgeTypesController

  uses_http_mock :sometimes

  setup :with_unique_user

  def user
    {:max_gears => 16, :consumed_gears => 4}
  end
  def domain
    {:id => 'test'}.tap do |o|
      o[:capabilities] = {} 
    end
  end
  def app(with_carts=false)
    {:id => 'testid', :name => 'test', :domain_id => 'test', :framework => 'php-5.3'}.tap do |o|
      o[:cartridges] = [{:name => 'php-5.3'}] if with_carts
    end
  end

  def mock_app
    Rails.cache.clear # cart metadata is mocked
    allow_http_mock
    ActiveResource::HttpMock.respond_to({},true) do |mock|
      mock.get '/broker/rest/user.json', json_header, user.to_json
      mock.get '/broker/rest/domain/test.json', json_header, domain.to_json
      mock.get '/broker/rest/domain/test.json?include=application_info', json_header, domain.to_json
      mock.get '/broker/rest/application/testid.json', json_header, app.to_json
      mock.get '/broker/rest/application/testid.json?include=cartridges', json_header, app(true).to_json
      mock.get '/broker/rest/cartridges.json', json_header, [{:name => 'fake-cart-1', :type => :embedded}].to_json
      mock.get '/broker/rest/cartridges.json', anonymous_json_header, [{:name => 'fake-cart-1', :type => :embedded}].to_json
      mock.get '/broker/rest/environment.json', anonymous_json_header, {:download_cartridges_enabled => true}.to_json
    end
    app
  end

  test "should list a new server cart with no metadata" do
    mock_app
    get :index, :application_id => 'testid-testname'
    assert_response :success

    assert a = assigns(:application)
    assert_equal app[:name], a.name
    assert_equal domain[:id], a.domain_id

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
    get :show, :application_id => 'testid-testname', :id => 'fake_cart_1'
    assert_response :success

    assert a = assigns(:application)
    assert_equal app[:name], a.name
    assert_equal domain[:id], a.domain_id

    assert_nil assigns(:cartridge_type)
    assert_not_found_page(/Cartridge Type 'fake_cart_1' does not exist/)
  end

  test "should show a new server cart with no metadata" do
    mock_app
    get :show, :application_id => 'testid-testname', :id => 'fake-cart-1'
    assert_response :success

    assert a = assigns(:application)
    assert_equal app[:name], a.name
    assert_equal domain[:id], a.domain_id

    assert cart = assigns(:cartridge_type)
    assert_equal 'fake-cart-1', cart.name
  end
end
