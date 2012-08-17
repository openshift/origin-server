require File.expand_path('../../test_helper', __FILE__)

class CartridgeTypesControllerTest < ActionController::TestCase

  test "should show index" do
    get :index, :application_id => with_app.name
    assert_response :success

    assert app = assigns(:application)
    assert_equal with_app.name, app.name
    assert domain = assigns(:domain)
    assert_equal with_app.domain_id, domain.id

    assert types = assigns(:installed)
    assert_equal 0, types.length
    assert types = assigns(:conflicts)
    assert_equal 0, types.length
    assert types = assigns(:requires)
    assert types.length > 0
    assert types = assigns(:blacklist)
    assert types.length > 0
    assert types = assigns(:carts)
    assert types.length > 0

    cached = CartridgeType.cached.all
    assert cached.all? {|t| (t.categories & [:installed, :inactive, 'inactive']).empty? }, cached.pretty_inspect
  end

  test "should show type page" do
    t = CartridgeType.embedded.first
    get :show, :application_id => with_app.name, :id => t.name
    assert_response :success
    assert type = assigns(:cartridge_type)
    assert_equal t.name, type.name
    assert assigns(:cartridge)
    assert assigns(:application)
    assert assigns(:domain)
  end

  test "should not raise on missing type" do
    # We allow arbitrary cartridges, but we may want to change that
    #assert_raise(StandardError) do
      get :show, :application_id => with_app.name, :id => 'missing_cartridge_type'
      assert_response :success
    #end
  end
end

