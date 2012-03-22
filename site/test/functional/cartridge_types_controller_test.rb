require 'test_helper'

class CartridgeTypesControllerTest < ActionController::TestCase
  
  def setup
    setup_integrated
    @application_type = ApplicationType.find 'ruby-1.8'
    @app = Application.new :name => 'test1', :as => @user
    @app.cartridge = @application_type.cartridge || @application_type.id
    @app.domain = @domain
    @app.save

    assert @app.errors.empty?, @app.errors.inspect
  end

  test "should list cartridges" do
    get_index
    assert cart_types = assigns(:cart_types)
    assert cart_types.length > 0
    assert installed_cart_types = assigns(:installed_cart_types)
    assert_equal 0, installed_cart_types.length
  end

  test "should list cartridges with one marked as installed" do
    get_index
    assert cart_types = assigns(:cart_types)
    assert cart_types.length > 0
    assert installed_cart_types = assigns(:installed_cart_types)
    assert_equal 0, installed_cart_types.length

    num_cart_types = cart_types.length

    @cartridge = Cartridge.new get_cart_params

    @cartridge.application = @app
    @cartridge.as = @user
    assert @cartridge.save

    get_index
    assert cart_types = assigns(:cart_types)
    assert cart_types.length > 0
    assert installed_cart_types = assigns(:installed_cart_types)
    assert_equal 1, installed_cart_types.length
    assert_equal num_cart_types - 1, cart_types.length
  end

  def get_index
    get :index, {:application_id => @app.id, :domain_id => @domain.id}
  end

  def get_cart_params
    {:name => 'cron-1.4', :type => 'embedded'}
  end

  def teardown
    domain = Domain.first :as => @user
    domain.destroy_recursive if domain
  end

end
