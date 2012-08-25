require File.expand_path('../../test_helper', __FILE__)

class CartridgesControllerTest < ActionController::TestCase
  def setup
    #with_domain
    with_unique_domain

    @domain.reload.applications.each {|app| app.destroy}

    @application_type = ApplicationType.find 'ruby-1.8'
    @app = Application.new :name => "cart#{uuid}", :as => @user
    @app.cartridge = @application_type.cartridge || @application_type.id
    @app.domain = @domain
    @app.save

    assert @app.errors.empty?, @app.errors.inspect
  end

  test "should create one cartridge" do
    post(:create, get_post_form)
    assert cart = assigns(:cartridge)
    assert cart.errors.empty?, cart.errors.inspect
    assert_response :success
    assert_template :next_steps
  end

  test "should create two cartridges" do
    post(:create, get_post_form)
    assert cart = assigns(:cartridge)
    assert cart.errors.empty?, cart.errors.inspect
    assert_response :success
    assert_template :next_steps

    post_form = get_post_form
    post_form[:cartridge][:name] = 'cron-1.4'
    post(:create, post_form)
    assert cart = assigns(:cartridge)
    assert cart.errors.empty?, cart.errors.inspect

    assert_response :success
    assert_template :next_steps
  end

  test "should error out if cartridge is installed" do
    post(:create, get_post_form)
    assert cart = assigns(:cartridge)
    assert cart.errors.empty?, cart.errors.inspect
    assert_response :success
    assert_template :next_steps

    post(:create, get_post_form)
    assert_response :success
    assert cart = assigns(:cartridge)
    assert !cart.errors.empty?
    assert cart.errors[:base].present?
    assert_equal 1, cart.errors[:base].length

    assert_response :success
    assert_template 'cartridge_types/show'
  end

  def get_post_form
    {:cartridge => {:name => 'mysql-5.1', :type => 'embedded'},
     :application_id => @app.id,
     :domain_id => @domain.id}
  end
end
