require File.expand_path('../../test_helper', __FILE__)

class CartridgesControllerTest < ActionController::TestCase

  def with_testable_app(remove_carts=false)
    use_app(:cart_testable_app) { Application.new({:name => "carttestable", :cartridge => 'ruby-1.9', :as => new_named_user('user_with_cartridge_testable_app')}) }.tap do |app|
      if remove_carts
        Cartridge.all(app.send(:child_options)).each do |cart|
          next if cart.name == app.framework
          #puts "Destroying cart #{cart.name}"
          begin
            cart.destroy
          rescue => e
            puts "Unable to delete cart #{cart.name}: #{e.message}, #{e.backtrace.join("\n")}"
          end
        end
      end
    end
  end

  test "should create one cartridge" do
    with_testable_app(true)

    post(:create, get_post_form)
    assert cart = assigns(:cartridge)
    assert cart.errors.empty?, cart.errors.to_hash.inspect
    assert_response :success
    assert_template :next_steps
  end

  test "should submit with a URL" do
    with_testable_app(false)
    Cartridge.any_instance.expects(:save).returns(true)

    post(:create, {:cartridge => {:name => 'custom', :url => 'https://foo.com'}, :application_id => with_testable_app.id, :domain_id => @domain.id})

    assert cart = assigns(:cartridge)
    assert cart.errors.empty?, cart.errors.to_hash.inspect
    assert_response :success
    assert_template :next_steps

    assert_equal 'https://foo.com', cart.url
    assert_nil cart.name
  end

  test "should create two cartridges" do
    with_testable_app(true)

    post(:create, get_post_form)
    assert cart = assigns(:cartridge)
    assert cart.errors.empty?, cart.errors.to_hash.inspect
    assert_response :success
    assert_template :next_steps

    post_form = get_post_form
    post_form[:cartridge][:name] = 'cron-1.4'
    post(:create, post_form)
    assert cart = assigns(:cartridge)
    assert cart.errors.empty?, cart.errors.to_hash.inspect

    assert_response :success
    assert_template :next_steps
  end

  test "should error out if cartridge is installed" do
    with_testable_app(true)

    post(:create, get_post_form)
    assert cart = assigns(:cartridge)
    assert cart.errors.empty?, cart.errors.to_hash.inspect
    assert_response :success
    assert_template :next_steps

    post(:create, get_post_form)
    assert_response :success
    assert cart = assigns(:cartridge)
    assert !cart.errors.empty?, cart.errors.to_hash.inspect
    assert cart.errors[:base].present?
    assert_equal 1, cart.errors[:base].length

    assert_response :success
    assert_template 'cartridge_types/show'
  end

  #test "should be able to view next steps cartridge page" do
  #  with_testable_app(true)

  #  get :next_steps, get_post_form
  #  assert_response :success
  #  assert_template :next_steps
  #end

  def get_post_form
    {:cartridge => {:name => 'mysql-5.1', :type => 'embedded'},
     :application_id => with_testable_app.id,
     :domain_id => @domain.id}
  end
end
