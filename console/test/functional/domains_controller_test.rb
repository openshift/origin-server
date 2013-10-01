require File.expand_path('../../test_helper', __FILE__)

class DomainsControllerTest < ActionController::TestCase

  @@user = nil

  def setup
    with_unique_user
  end

  def with_particular_user
    if @@user
      set_user(@@user)
    else
      @@user = @user
    end
    with_domain
  end

  def with_domain
    @domain = Domain.first :as => @user
    unless @domain
      @domain = Domain.new(get_post_form.merge(:as => @user))
      flunk @domain.errors.inspect unless @domain.save
    end
  end

  def unique_name_format
    "d#{uuid[0..10]}%i"
  end

  test "should display domain list" do
    with_domain

    get :index

    assert domains = assigns(:domains)
    assert domain = domains.first
    assert_equal @domain, domain
    assert domain.capabilities.present?
    assert domain.members.present?
    assert assigns(:can_create) != nil
  end

  test "should display domain creation form" do
    get :new

    assert domain = assigns(:domain)
    assert_response :success
    assert_template :new
  end

  test "should create domain" do
    post :create, {:domain => get_post_form}

    assert domain = assigns(:domain)
    assert domain.errors.empty?, domain.errors.inspect
    assert_redirected_to settings_path
  end

  test "should create domain and redirect" do
    post :create, {:domain => get_post_form, :then => '/redirect?param1=value1&param2=value2', :domain_param => 'param1'}

    assert domain = assigns(:domain)
    assert domain.errors.empty?, domain.errors.inspect
    assert_redirected_to "/redirect?param1=#{domain.name}&param2=value2"
  end

  test "should clear domain session cache" do
    Rails.cache.write(@controller.domains_cache_key, [])
    post :create, {:domain => get_post_form}

    assert domain = assigns(:domain)
    assert domain.errors.empty?, domain.errors.inspect
    assert_redirected_to settings_path
    assert_nil Rails.cache.read(@controller.domains_cache_key)
  end

  test "should assign errors on empty name" do
    post :create, {:domain => get_post_form.merge(:name => '')}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert !domain.errors[:name].nil?
    assert domain.errors[:name].include? 'Must be a minimum of 1 and maximum of 16 characters.' 
    assert_template :new
  end

  test "should assign errors on long name" do
    post :create, {:domain => get_post_form.merge(:name => 'aoeu'*2000)}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length, domain.errors.inspect
    assert_template :new
  end

  test "should assign errors on invalid name" do
    post :create, {:domain => get_post_form.merge(:name => '@@@@')}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length, domain.errors.inspect
    assert_template :new
  end

  test "should assign errors on duplicate name" do
    assert (domain = Domain.new(get_post_form.merge(:as => unique_user))).save, domain.errors.inspect

    post :create, {:domain => get_post_form.merge(:name => domain.name)}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length, domain.errors.inspect
    assert_template :new
  end

  #test "should allow only one domain" do
  #  with_domain

  #  post :create, {:domain => {:name => unique_name}}

  #  assert domain = assigns(:domain)
  #  assert !domain.errors.empty?
  #  assert domain.errors[:name].present?, domain.errors.inspect
  #  assert_equal 1, domain.errors[:name].length, domain.errors.inspect
  #  assert_template :new
  #end

  test "should show edit domain page" do
    with_domain

    get :edit
    assert_template :edit
    assert_response :success
  end

  test "should show domain info page" do
    with_domain

    get :show, {:id => @domain.id}
    assert_template :show
    assert_response :success
  end

  test "should update domain" do
    with_particular_user

    put :update, {:domain => {:name => unique_name}}

    assert domain = assigns(:domain)
    assert domain.errors.empty?, domain.errors.inspect
    assert_redirected_to domain_path(domain)
  end

  test "should update domain and clear session cache" do
    with_particular_user
    Rails.cache.write(@controller.domains_cache_key, [])

    put :update, {:domain => {:name => unique_name}}

    assert domain = assigns(:domain)
    assert domain.errors.empty?, domain.errors.inspect
    assert_redirected_to domain_path(domain)
    assert_nil Rails.cache.read(@controller.domains_cache_key)
  end

  test "update should assign errors on empty name" do
    with_particular_user

    put :update, {:domain => {:name => ''}}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert !domain.errors[:name].nil?
    assert domain.errors[:name].include? 'Must be a minimum of 1 and maximum of 16 characters.' 
    assert_template :edit
  end

  test "update should assign errors on long name" do
    with_particular_user

    put :update, {:domain => {:name => 'aoeu'*2000}}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :edit
  end

  test "update should assign errors on invalid name" do
    with_particular_user

    put :update, {:domain => {:name => '@@@@'}}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?, domain.inspect
    assert domain.errors[:name].present?, domain.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :edit
  end

  test "update should assign errors on duplicate name" do
    with_particular_user
    assert (domain = Domain.new(get_post_form.merge(:name => "d#{new_uuid[0..12]}", :as => unique_user))).save, domain.errors.inspect

    put :update, {:domain => {:name => domain.name}}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :edit
  end

  def get_post_form
    {:name => "d#{uuid[0..12]}"}
  end
end
