require File.expand_path('../../test_helper', __FILE__)

class CartridgeTypesControllerTest < ActionController::TestCase
  def setup
  end

  def with_app
    unless @app
      with_unique_domain
      @application_type = ApplicationType.find 'ruby-1.8'
      @app = Application.new :name => uuid, :as => @user
      @app.cartridge = @application_type.cartridge || @application_type.id
      @app.domain = @domain
      @app.save

      assert @app.errors.empty?, @app.errors.inspect
    end

    {:application_id => @app.id, :domain_id => @domain.id}
  end

  test "should build url to cartridge" do
    cart = CartridgeType.new(:name => 'haproxy-1.4')
    assert 'haproxy-1.4', cart.to_param
    url = application_cartridge_type_path(Application.new(:name => '1'), cart)
    assert url
  end

  test "should list cartridges" do
    get :index, with_app
    assert cart_types = assigns(:carts)
    assert cart_types.length > 0
    assert installed_cart_types = assigns(:installed)
    assert_equal 0, installed_cart_types.length
  end

  test "should list cartridges with one marked as installed" do
    get :index, with_app
    assert cart_types = assigns(:carts)
    assert cart_types.length > 0
    assert installed_cart_types = assigns(:installed)
    assert_equal 0, installed_cart_types.length

    num_cart_types = cart_types.length

    @cartridge = Cartridge.new get_cart_params

    @cartridge.application = @app
    @cartridge.as = @user
    assert @cartridge.save

    get :index, with_app
    assert cart_types = assigns(:carts)
    assert cart_types.length > 0
    assert installed_cart_types = assigns(:installed)
    assert_equal 1, installed_cart_types.length
    assert_equal num_cart_types - 1, cart_types.length
  end

  test "should show cart page" do
    get :show, with_app.merge(:id => CartridgeType.embedded(:as => @user)[0].to_param)
    assert cart = assigns(:cartridge)
    assert type = assigns(:cartridge_type)
  end

  def get_cart_params
    {:name => 'cron-1.4', :type => 'embedded'}
  end
end
