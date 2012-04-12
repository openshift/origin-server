require File.expand_path('../../test_helper', __FILE__)

class DomainsControllerTest < ActionController::TestCase

  @@user = nil

  def setup
    with_unique_user
  end

  def with_particular_user
    if @@user
      @user = @@user
    else
      @@user = @user
    end
    @domain = Domain.first :as => @user
    unless @domain
      @domain = Domain.new(get_post_form.merge(:as => @user))
      flunk @domain.errors.inspect unless @domain.save
    end
  end

  def unique_name_format
    "d#{uuid[0..10]}%i"
  end

  test "should create domain" do
    post :create, {:domain => get_post_form}

    assert domain = assigns(:domain)
    assert domain.errors.empty?, domain.errors.inspect
    assert_redirected_to account_path
  end

  test "should assign errors on empty name" do
    post :create, {:domain => get_post_form.merge(:name => '')}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 2, domain.errors[:name].length, domain.errors.inspect, "Bug 812060 has been fixed, change to 1"
    assert_template :new
  end

  test "should assign errors on long name" do
    post :create, {:domain => get_post_form.merge(:name => 'aoeu'*2000)}
    
    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :new
  end

  test "should assign errors on invalid name" do
    post :create, {:domain => get_post_form.merge(:name => '@@@@')}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :new
  end

  test "should assign errors on duplicate name" do
    (domain = Domain.new(get_post_form.merge(:as => @user))).save!

    post :create, {:domain => get_post_form.merge(:name => domain.name)}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :new
  end

  test "should show edit domain page" do
    get :edit
    assert_template :edit
    assert_response :success
  end

  test "should update domain" do
    with_particular_user

    put :update, {:domain => get_post_form.merge(:name => unique_name)}

    assert domain = assigns(:domain)
    assert domain.errors.empty?, domain.errors.inspect
    assert_redirected_to account_path
  end

  test "update should assign errors on empty name" do
    with_particular_user

    put :update, {:domain => @domain.attributes.merge(:name => '')}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :new
  end

  test "update should assign errors on long name" do
    with_particular_user

    put :update, {:domain => @domain.attributes.merge(:name => 'aoeu'*2000)}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :new
  end

  test "update should assign errors on invalid name" do
    with_particular_user

    put :update, {:domain => @domain.attributes.merge(:name => '@@@@')}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :new
  end

  test "update should assign errors on duplicate name" do
    with_particular_user
    assert (domain = Domain.new(get_post_form.merge(:as => setup_new_user(true)))).save, domain.errors.inspect

    put :update, {:domain => @domain.attributes.merge(:name => domain.name)}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :new
  end

  def get_post_form
    {:name => unique_name}
  end
end
