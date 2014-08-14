require File.expand_path('../../test_helper', __FILE__)

class CartridgeTypesControllerTest < ActionController::TestCase

  test "should show index" do
    RestApi.stubs(:download_cartridges_enabled?).returns(true)

    get :index, :application_id => with_app.to_param
    assert_response :success

    assert app = assigns(:application)
    assert_equal with_app.name, app.name
    assert_equal with_app.domain_id, app.domain_id

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
    assert cached.all? {|t| (t.tags & [:installed, :inactive, 'inactive']).empty? }, cached.pretty_inspect

    assert_select "h3", 'Install your own cartridge'
    assert_select "input[type=submit][title='Download a cartridge into this app']"
  end

  test "should show type page" do
    t = CartridgeType.embedded.first
    get :show, :application_id => with_app.to_param, :id => t.name
    assert_response :success
    assert type = assigns(:cartridge_type)
    assert_equal t.name, type.name
    assert assigns(:cartridge)
    assert assigns(:application)
    assert assigns(:gear_sizes)
    assert_select ".indicator-gear-increase", "+0"
    assert_select ".cartridge_gear_size", "small"
  end

  test "should show type page for scalable" do
    t = CartridgeType.embedded.find(&:service?)
    get :show, :application_id => with_scalable_app.to_param, :id => t.name
    assert_response :success
    assert type = assigns(:cartridge_type)
    assert_equal t.name, type.name
    assert assigns(:cartridge)
    assert assigns(:application)
    assert assigns(:gear_sizes)
    assert_select ".indicator-gear-increase", /\+1\b/
    assert_select ".cartridge_gear_size", "small"
  end

  test "should show type page for scalable with gear sizes" do
    gear_sizes = %w(small medium large)
    CartridgeTypesController.any_instance.stubs(:add_cartridge_gear_sizes).returns(gear_sizes)

    t = CartridgeType.embedded.find(&:service?)
    get :show, :application_id => with_scalable_app.to_param, :id => t.name
    assert_response :success
    assert assigns(:gear_sizes)
    assert_select ".indicator-gear-increase", /\+1\b/
    assert_select "#cartridge_gear_size" do
      assert_select 'option', gear_sizes.delete_at(0)
    end
  end

  test "should show type page with restricted gear sizes for cartridge" do
    Domain::Capabilities.any_instance.stubs(:allowed_gear_sizes).returns(%w(small medium large))

    CartridgeType.any_instance.stubs(:valid_gear_sizes).returns(['medium', 'large'])
    CartridgeType.any_instance.stubs(:valid_gear_sizes?).returns(true)

    t = CartridgeType.embedded.find(&:service?)
    get :show, :application_id => with_scalable_app.to_param, :id => t.name
    assert_response :success
    assert gear_sizes = assigns(:gear_sizes)
    assert_equal gear_sizes.length, 2
    assert_select "#cartridge_gear_size" do
      assert_select 'option', 'medium'
    end
    assert_select '.text-warning', /Supported gear sizes: medium, large/
  end

  test "should show type page with one gear size match for cartridge" do
    Domain::Capabilities.any_instance.stubs(:allowed_gear_sizes).returns(%w(small medium))

    CartridgeType.any_instance.stubs(:valid_gear_sizes).returns(['medium'])
    CartridgeType.any_instance.stubs(:valid_gear_sizes?).returns(true)

    t = CartridgeType.embedded.find(&:service?)
    get :show, :application_id => with_scalable_app.to_param, :id => t.name
    assert_response :success
    assert gear_sizes = assigns(:gear_sizes)
    assert_equal gear_sizes.length, 1
    assert_select ".cartridge_gear_size", "medium"
    assert_select '.text-warning', /Supported gear size: medium/
  end

  test "should show error on type page without valid gear sizes for cartridge" do
    Domain::Capabilities.any_instance.stubs(:allowed_gear_sizes).returns(%w(small))

    CartridgeType.any_instance.stubs(:valid_gear_sizes).returns(['medium', 'large'])
    CartridgeType.any_instance.stubs(:valid_gear_sizes?).returns(true)

    t = CartridgeType.embedded.first
    get :show, :application_id => with_app.to_param, :id => t.name
    assert_response :success
    assert_select '.text-warning', /Supported gear sizes: medium, large/
    assert_select '.alert-error', /The gear sizes available for this application or your account are not compatible with this cartridge/
  end

  test "should show custom url page" do
    get :show, :application_id => with_app.id, :id => 'custom', :url => 'https://foo.com#bar'

    assert_response :success
    assert type = assigns(:cartridge_type)
    assert_equal 'https://foo.com#bar', type.url
    assert assigns(:cartridge)
    assert assigns(:application)

    assert_select 'h3', 'bar'
    assert_select '.alert', /This cartridge will be downloaded/
    assert_select 'dd', %r(https://foo.com#bar)
    assert_select '.text-warning', /Downloaded cartridges do not receive updates automatically/
    assert_select 'a[href=https://foo.com#bar]', 'bar'
    assert_select ".indicator-gear-increase", "+0"
  end

  test "should add http scheme for custom url page" do
    get :show, :application_id => with_app.id, :id => 'custom', :url => 'foo.com#bar'

    assert_response :success
    assert type = assigns(:cartridge_type)
    assert_equal 'http://foo.com#bar', type.url
    assert assigns(:cartridge)
    assert assigns(:application)

    assert_select 'h3', 'bar'
    assert_select '.alert', /This cartridge will be downloaded/
    assert_select 'dd', %r(http://foo.com#bar)
    assert_select '.text-warning', /Downloaded cartridges do not receive updates automatically/
    assert_select 'a[href=http://foo.com#bar]', 'bar'
    assert_select ".indicator-gear-increase", "+0"
  end

  test "should show custom url page for scalable app" do
    get :show, :application_id => with_scalable_app.id, :id => 'custom', :url => 'https://foo.com#bar'

    assert_response :success
    assert type = assigns(:cartridge_type)
    assert_equal 'https://foo.com#bar', type.url
    assert assigns(:cartridge)
    assert assigns(:application)

    assert_select 'h3', 'bar'
    assert_select '.alert', /This cartridge will be downloaded/
    assert_select 'dd', %r(https://foo.com#bar)
    assert_select 'a[href=https://foo.com#bar]', 'bar'
    assert_select '.text-warning', /Downloaded cartridges do not receive updates automatically/
    assert_select ".indicator-gear-increase", /\+0\-1\b/
  end

  test "should not raise on missing type" do
    # We allow arbitrary cartridges, but we may want to change that
    #assert_raise(StandardError) do
      get :show, :application_id => with_app.to_param, :id => 'missing_cartridge_type'
      assert_response :success
    #end
  end
end

