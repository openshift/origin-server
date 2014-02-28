require File.expand_path('../../test_helper', __FILE__)

class StorageControllerTest < ActionController::TestCase
  test "should show with max storage per gear" do
    get :show, {:application_id => with_storage_app.to_param}

    assert user = assigns(:user)
    assert max_storage = assigns(:max_storage)
    assert_not_nil user.capabilities[:max_storage_per_gear]
    assert_equal user.capabilities[:max_storage_per_gear], max_storage
    assert usage_rates = assigns(:usage_rates)
    assert_equal user.usage_rates, usage_rates
    assert_response :success
  end

  test "should not be able to set storage higher than user's max storage per gear" do
    set_storage(with_storage_app,'ruby-1.8',100,false)

    assert flash[:error].length == 1, "Should only get one error"
    assert /^User can not exceed max storage quota per gear/, flash[:error].first
  end

  test "setting storage with single cartridge" do
    set_storage(with_storage_app,'ruby-1.8',5)
    check_storage(5)
  end

  test "setting storage with embedded database" do
    set_storage(with_storage_app(:db => true),'ruby-1.8',5)
    check_storage(5)
  end

  test "setting storage with scaled cartridge and embedded database" do
    set_storage(with_storage_app(:db => true, :scale => true),'ruby-1.8',5)
    check_storage(5)

    set_storage(with_storage_app(:db => true, :scale => true, :clear => false),'mysql-5.1',3)
    check_storage(3,5)
  end

  def set_storage(app,cart,value,check = true)
    post :update, {:application_id => app.to_param, :id => cart, :cartridge => {:additional_gear_storage => value}}
    if check
      app = assigns(:application)
      assert_redirected_to application_storage_path(app)
      assert /^Updated storage for cartridge/, flash[:success].first
    end
  end

  def check_storage(value, other = 0)
    app = assigns(:application)

    # Get the page again so we know we have updated information
    get :show, {:application_id => app.to_param}
    app = assigns(:application)
    cartridge = assigns(:cartridge)
    gear_groups = assigns(:gear_groups)

    # Partitition the gear groups to find the one with our cart
    (with_cart,without_cart) = gear_groups.partition{|group| group.cartridges.include?(cartridge) }

    # Make sure our gear groups have the right values
    [
      {:carts => with_cart, :value => value},
      {:carts => without_cart, :value => other}
    ].each do |values|
      val = values[:value]
      values[:carts].map(&:cartridges).flatten.each do |cart|
        assert_equal val, cart.additional_gear_storage, "Cartridge #{cart.name} has incorrect additional_gear_storage"
      end
    end
  end

  def with_storage_app(args = {})
    args = {
      :scale => false,
      :db    => false,
      :clear => true
    }.merge(args)

    name = "stor"
    name << "scal" if args[:scale]
    name << "db" if args[:db]

    app_args = {
      :name => name,
      :cartridge => 'ruby-1.8',
      :scale => args[:scale] || false,
      :as => new_named_user("user_with_extra_storage@test.com")
    }

    use_app(name){ Application.new(app_args) }.tap do |app|
      add_database(app) if args[:db]
      clear_storage(app) if args[:clear]
    end
  end

  def clear_storage(app)
    Cartridge.all(app.send(:child_options)).each do |cart|
      cart.additional_gear_storage = 0
      cart.save!
    end
  end

  def add_database(app)
    unless Cartridge.all(app.send(:child_options)).map(&:name).include?('mysql-5.1')
      cart = Cartridge.new({:type => 'embedded', :name => 'mysql-5.1'})
      cart.application = app
      cart.as = app.as
      cart.save!
    end
  end
end
