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

    Domain.expects(:find).with() {|id, *args| id == @domain.id }.returns(@domain)

    get :edit, {:id => @domain.id}
    assert_template :edit
    assert_response :success
  end

  test "should show domain info page" do
    with_domain

    Domain.expects(:find).with() {|id, *args| id == @domain.id }.returns(@domain)

    get :show, {:id => @domain.id}
    assert_template :show
    assert_response :success
  end

  test "should update domain" do
    with_particular_user

    Domain.expects(:find).with() {|id, *args| id == @domain.id }.returns(@domain)

    put :update, {:id => @domain.id, :domain => {:name => unique_name}}

    assert domain = assigns(:domain)
    assert domain.errors.empty?, domain.errors.inspect
    assert_redirected_to domain_path(domain)
  end

  test "should update domain and clear session cache" do
    with_particular_user
    Rails.cache.write(@controller.domains_cache_key, [])

    put :update, {:id => @domain.id, :domain => {:name => unique_name}}

    assert domain = assigns(:domain)
    assert domain.errors.empty?, domain.errors.inspect
    assert_redirected_to domain_path(domain)
    assert_nil Rails.cache.read(@controller.domains_cache_key)
  end

  test "update should assign errors on empty name" do
    with_particular_user

    put :update, {:id => @domain.id, :domain => {:name => ''}}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert !domain.errors[:name].nil?
    assert domain.errors[:name].include? 'Must be a minimum of 1 and maximum of 16 characters.' 
    assert_template :edit
  end

  test "update should assign errors on long name" do
    with_particular_user

    put :update, {:id => @domain.id, :domain => {:name => 'aoeu'*2000}}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :edit
  end

  test "update should assign errors on invalid name" do
    with_particular_user

    put :update, {:id => @domain.id, :domain => {:name => '@@@@'}}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?, domain.inspect
    assert domain.errors[:name].present?, domain.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :edit
  end

  test "update should assign errors on duplicate name" do
    with_particular_user
    assert (domain = Domain.new(get_post_form.merge(:name => "d#{new_uuid[0..12]}", :as => unique_user))).save, domain.errors.inspect

    put :update, {:id => @domain.id, :domain => {:name => domain.name}}

    assert domain = assigns(:domain)
    assert !domain.errors.empty?
    assert domain.errors[:name].present?, domain.errors.inspect
    assert_equal 1, domain.errors[:name].length
    assert_template :edit
  end

  test "should show delete page" do
    with_particular_user

    get :delete, {:id => @domain.id}

    assert_response :success
    assert_template :delete
    assert domain = assigns(:domain)
  end

  test "should not show delete page for domain with applications" do
    with_particular_user
    Domain.any_instance.expects(:application_count).returns(1)

    get :delete, {:id => @domain.id}

    assert_redirected_to domain_path(@domain)
    assert flash[:info] =~ /removed/, "Expected a message about removing applications"
  end

  test "should delete domain successfully" do
    with_particular_user

    delete :destroy, {:id => @domain.id}

    assert_redirected_to settings_path
    assert flash[:success] =~ /deleted/, "Expected a message about removing applications"
    assert_raises(RestApi::ResourceNotFound) { Domain.find(@domain.id, :as => unique_user) }
  end

  test "should show domain delete button for owner" do
    with_particular_user
    Domain.any_instance.expects(:owner?).at_least(0).returns(true)
    Domain::Member.any_instance.expects(:explicit_role?).at_least(0).returns(false)
    get :show, {:id => @domain.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", /Delete this domain/
    assert_select "a:content(?)", /Leave Domain/, :count => 0
  end

  test "should show leave domain button for explicit members" do
    with_particular_user
    Domain.any_instance.expects(:owner?).at_least(0).returns(false)
    Domain::Member.any_instance.expects(:explicit_role?).at_least(0).returns(true)
    get :show, {:id => @domain.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", /Delete this domain/, :count => 0
    assert_select "a:content(?)", /Leave Domain/
  end

  test "should hide leave domain button for implicit members" do
    with_particular_user
    Domain.any_instance.expects(:owner?).at_least(0).returns(false)
    Domain::Member.any_instance.expects(:explicit_role?).at_least(0).returns(false)
    get :show, {:id => @domain.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", /Delete this domain/, :count => 0
    assert_select "a:content(?)", /Leave Domain/, :count => 0
  end

  test "should render uneditable members successfully" do
    with_particular_user
    Domain.any_instance.expects(:admin?).at_least(0).returns(false)
    get :show, {:id => @domain.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", "Add members...", :count => 0
    assert_select "a:content(?)", "Add a user...", :count => 0
    assert_select "a:content(?)", "Add a team...", :count => 0
    assert_select "a.edit-members:content(?)", "Edit members...", :count => 0
  end

  test "should render editable members with only owner successfully" do
    with_particular_user
    Console.config.capabilities_model_class.any_instance.expects(:max_teams).at_least(0).returns(1)
    Domain.any_instance.expects(:admin?).at_least(0).returns(true)
    get :show, {:id => @domain.id}
    assert_template :show
    assert_response :success
    assert_select "tr.type-team", :count => 0
    assert_select "tr.type-user", :count => 0
    assert_select "a:content(?)", "Add members..."
    assert_select "a.edit-members:content(?)", "Edit members..."
  end

  test "should render editable members with teams and implicit users successfully" do
    with_particular_user
    original_members = @domain.members
    Console.config.capabilities_model_class.any_instance.expects(:max_teams).at_least(0).returns(1)
    Domain.any_instance.expects(:admin?).at_least(0).returns(true)
    Domain.any_instance.expects(:members).at_least(0).returns(
      [
        # Explicit team
        Domain::Member.new(:type => 'team', :explicit_role => 'view', :role => 'view', :id => '123'),
        # Implicit member of that team
        Domain::Member.new(:type => 'user', :explicit_role => nil,    :role => 'view', :id => '234', :login => 'alice', :from => [{:type => 'team', :id => '123', :role => 'view'}])
      ] + original_members)
    get :show, {:id => @domain.id}
    assert_template :show
    assert_response :success
    assert_select "tr.type-team"
    assert_select "tr.type-user", :count => 0
    assert_select "tr.team-details td:content(?)", /alice/
    assert_select "a:content(?)", "Add members...", :count => 0
    assert_select "a:content(?)", "Add a user..."
    assert_select "a:content(?)", "Add a team..."
    assert_select "a.edit-members:content(?)", "Edit members..."
  end

  test "should render editable members with teams and explicit users successfully" do
    with_particular_user
    original_members = @domain.members
    Console.config.capabilities_model_class.any_instance.expects(:max_teams).at_least(0).returns(1)
    Domain.any_instance.expects(:admin?).at_least(0).returns(true)
    Domain.any_instance.expects(:members).at_least(0).returns(
      [
        # Explicit team
        Domain::Member.new(:type => 'team', :explicit_role => 'edit',  :role => 'edit',  :id => '123'),
        # Implicit member of that team who also has an explicit role which is lower
        Domain::Member.new(:type => 'user', :explicit_role => 'view',  :role => 'edit',  :id => '234', :login => 'alice', :from => [{:type => 'team', :id => '123', :role => 'edit'}]),
        # Explicit member who is not in any teams
        Domain::Member.new(:type => 'user', :explicit_role => 'admin', :role => 'admin', :id => '345', :login => 'steve'),
      ] + original_members)
    get :show, {:id => @domain.id}
    assert_template :show
    assert_response :success
    assert_select "tr.type-team"
    assert_select "tr.type-team select[name='members[][role]'] option[selected='selected'][value='edit']"
    assert_select "tr.team-details td:content(?)", /alice/

    assert_select "tr.type-user", :count => 2
    # Ensure the explicit role is the one pre-selected in the dropdown for the user
    assert_select "tr.type-user select[name='members[][role]'] option[selected='selected'][value='view']"
    assert_select "tr.type-user select[name='members[][role]'] option[selected='selected'][value='admin']"

    assert_select "a:content(?)", "Add members...", :count => 0
    assert_select "a:content(?)", "Add a user..."
    assert_select "a:content(?)", "Add a team..."
    assert_select "a.edit-members:content(?)", "Edit members..."
  end

  test "should hide team add function in members section" do
    with_particular_user
    Domain.any_instance.expects(:admin?).at_least(0).returns(true)
    Console.config.capabilities_model_class.any_instance.expects(:max_teams).at_least(0).returns(0)
    Console.config.capabilities_model_class.any_instance.expects(:view_global_teams).at_least(0).returns(false)

    get :show, {:id => @domain.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", "Add a user..."
    assert_select "a:content(?)", "Add a team...", :count => 0
  end

  def get_post_form
    {:name => "d#{uuid[0..12]}"}
  end
end
