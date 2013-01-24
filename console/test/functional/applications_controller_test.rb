require File.expand_path('../../test_helper', __FILE__)

class ApplicationsControllerTest < ActionController::TestCase

  test "should create and delete app" do
    # in applications_controller_sanity_test
  end

  test 'should redirect new to types' do
    with_configured_user
    get :new
    assert_redirected_to application_types_path
  end

  test 'report and clear cached error if domain not found' do
    with_configured_user
    session[:domain] = 'does_not_exist'
    get :index
    assert_not_found_page(/Domain 'does_not_exist' does not exist/)
    assert_nil session[:domain]
  end

  test 'index will cache domain' do
    with_unique_domain
    get :index
    assert_equal @domain.id, session[:domain]
  end

  test 'index will use cached domain' do
    with_unique_domain
    session[:domain] = @domain.id
    Domain.expects(:find).never
    get :index
    assert_equal @domain.id, session[:domain]
  end

  test "should assign domain errors on empty name" do
    with_unique_user
    app_params = get_post_form
    post(:create, {:application => app_params})

    assert_template 'application_types/show'
    assert app = assigns(:application)
    assert !app.errors.empty?
    assert app.errors[:domain_name].present?, app.errors.inspect
    assert !app.errors[:domain_name].nil?
    assert app.errors[:domain_name][0].include? 'Namespace is required and cannot be blank.'
  end

  test "should assign errors on empty name" do
    with_domain
    app_params = get_post_form
    app_params[:name] = ''
    post(:create, {:application => app_params})

    assert_template 'application_types/show'
    assert app = assigns(:application)
    assert !app.errors.empty?
    assert app.errors[:name].present?, app.errors.inspect
    assert_equal 1, app.errors[:name].length
  end

  test "should assign errors when advanced form" do
    with_domain
    app_params = get_post_form
    app_params[:name] = ''
    post(:create, {:application => app_params, :application_type => 'custom', :advanced => true})

    assert_template 'application_types/show'
    assert app = assigns(:application)
    assert !app.errors.empty?
    assert app.errors[:name].present?, app.errors.to_hash.inspect
    assert_equal 1, app.errors[:name].length

    assert_select '.alert.alert-error', /No cartridges are defined for this type/i
    assert_select 'h3 > span.text-warning', 'None'
    assert_select '.btn-primary[disabled=disabled]'
    assert_select "select[name='application[scale]']"
    assert_select "input[name='application[initial_git_url]']" do |inputs|
      assert_nil inputs.first['value']
    end
    #assert_select "input[name='application[initial_git_branch]']" do |inputs|
    #  assert_nil inputs.first['value']
    #end
  end

  test "should assign errors when advanced form with carts" do
    with_domain
    app_params = get_post_form
    app_type = {
      :id => 'custom',
      :cartridges => ['ruby-'],
      :initial_git_url => 'http://foo.com',
      :initial_git_branch => 'bar',
    }
    app_params[:name] = ''
    app_params[:cartridges] = ['ruby-1.8']
    app_params[:scale] = 'true'
    post(:create, {:application => app_params, :application_type => app_type, :advanced => true})

    assert_template 'application_types/show'
    assert app = assigns(:application)
    assert !app.errors.empty?
    assert app.errors[:name].present?, app.errors.inspect
    assert_equal 1, app.errors[:name].length

    assert_select '.alert.alert-error', /Application name is required/i
    assert_select "select[name='application[scale]'] > option[selected]", 'Scale with web traffic'
    assert_select "input[name='application[initial_git_url]'][value=http://foo.com]"
    #assert_select "input[name='application[initial_git_branch]'][value=bar]"
    assert_select "select[name='application[cartridges][]'] > option[selected]", 'Ruby 1.8'
  end

  test "should assign errors on long name" do
    with_domain
    app_params = get_post_form
    app_params[:name] = 'aoeu'*30
    post(:create, {:application => app_params})

    assert_template 'application_types/show'
    assert app = assigns(:application)
    assert assigns(:domain)
    assert !app.errors.empty?
    assert app.errors[:name].present?, app.errors.inspect
    assert_equal 1, app.errors[:name].length, app.errors.inspect
  end

  test "should assign errors on invalid characters" do
    with_domain
    app_params = get_post_form
    app_params[:name] = '@@ @@'
    post(:create, {:application => app_params})

    assert_template 'application_types/show'
    assert app = assigns(:application)
    assert assigns(:domain)
    assert !app.errors.empty?
    assert app.errors[:name].present?, app.errors.inspect
    assert_equal 1, app.errors[:name].length, app.errors.inspect
  end

  test "should assign errors on invalid gear size" do
    with_domain
    app_params = get_post_form
    app_params[:gear_profile] = 'foobar'
    post(:create, {:application => app_params})

    assert_template 'application_types/show'
    assert app = assigns(:application)
    assert !app.persisted?
    assert !app.errors.empty?
    assert app.errors[:gear_profile].present?, app.errors.to_hash.inspect
    assert_equal 1, app.errors[:gear_profile].length, app.errors.to_hash.inspect
    assert app.errors[:gear_profile][0].include? 'Invalid size: foobar.'
  end

  test "should retrieve application list" do
    app = with_app

    # get full version of the list
    get(:index)
    apps = assigns(:applications)
    assert apps
    assert_equal apps.length, 1
    apps[0].name == app.name
    assert_response :success
  end

  test "should filter application list with name" do
    app = with_app

    # get a filtered version of the list
    get(:index, :applications_filter => {:name => app.name})
    apps = assigns(:applications)
    assert apps
    assert_equal apps.length, 1
    assert_equal apps[0].name, app.name
    assert_response :success
  end

  test "should not filter application list with other name" do
    app = with_app

    # get a filtered version of the list
    get(:index, :applications_filter => {:name => 'not'})
    apps = assigns(:applications)
    assert apps
    assert_equal apps.length, 0
    assert_response :success
  end

  test "should retrieve application details" do
    get :show, :id => with_app.name
    assert_response :success
    assert app = assigns(:application)
    assert_equal with_app.name, app.name
    assert groups = assigns(:gear_groups)
    assert_equal 1, groups.length
    assert (groups[0].cartridges.map(&:name) - with_app.cartridges.map(&:name)).empty?
    assert groups[0].cartridges[0].display_name
    assert domain = assigns(:domain)
    assert !assigns(:has_keys)
  end

  test "should retrieve application details with has_sshkey cache set" do
    session[:has_sshkey] = true
    get :show, :id => with_app.name
    assert_response :success
    assert app = assigns(:application)
    assert has_keys = assigns(:has_keys)
  end

  test "should retrieve scalable application details" do
    get :show, :id => with_scalable_app.name
    assert_response :success
    assert app = assigns(:application)
    assert_equal with_scalable_app.name, app.name
    assert groups = assigns(:gear_groups)
    assert_equal 1, groups.length, groups.pretty_inspect
    assert (groups[0].cartridges.map(&:name) - with_scalable_app.cartridges.map(&:name)).empty?
    assert domain = assigns(:domain)
  end

  test "should retrieve application get started page" do
    get :get_started, :id => with_app.name
    assert_response :success
    assert app = assigns(:application)
    assert_equal with_app.name, app.name
  end

  test "should retrieve application delete confirm page" do
    get :delete, :id => with_app.name
    assert_response :success
    assert app = assigns(:application)
    assert_equal with_app.name, app.name
  end

  test "should result in a not found error when retrieving an application that does not exist" do
    with_app
    with_rescue_from{ get :show, :id => 'idontexist' }
    assert_response :success
    assert_select 'h1', /Application 'idontexist' does not exist/
    assert_select 'a', "Application #{with_app.name}"
  end

  test "should result in a not found when retrieving a domain that does not exist" do
    with_unique_user
    with_rescue_from{ get :show, :id => 'idontexist' }
    assert_response :success
    assert_select 'h1', /Domain does not exist/
  end

  test "should result in a not found when retrieving an application that does not exist" do
    with_domain
    get :show, :id => 'idontexist'
    assert_response :success
    assert_select 'h1', /Application 'idontexist' does not exist/
  end

  test 'invalid destroy should render page' do
    Application.any_instance.expects(:destroy).returns(false)
    delete :destroy, :id => with_app.name
    assert_response :success
    assert_template :delete
  end

  test 'should support the creation of scalable apps with medium gears for privileged users' do
    with_user_with_multiple_gear_sizes
    find_or_create_domain

    user = User.find(:one, :as => @controller.current_user)
    @domain.applications.each(&:destroy) unless user.gears_free >= 2

    medium_gear_app = {
      :name => uuid,
      :application_type => 'cart!php-5.3',
      :gear_profile => 'medium',
      :scale => 'true',
      :domain_name => @domain.name
    }

    # Make the request
    post(:create, {:application => medium_gear_app})

    # Confirm app attributes
    assert app = assigns(:application)
    assert app.errors.empty?, app.errors.inspect
    assert_equal 'medium', app.gear_profile
    assert_equal 'true', app.scale.to_s
    assert app.persisted?

    app.destroy
  end

  test 'should not allow medium gears for non-privileged users' do
    with_unique_domain
    medium_gear_app_form = {
      :name => uuid,
      :application_type => 'cart!php-5.3',
      :gear_profile => 'medium',
      :domain_name => @domain.name
    }

    post(:create, {:application => medium_gear_app_form})

    assert_response :success
    assert app = assigns(:application)
    assert app.errors.messages[:gear_profile][0].include? 'Invalid size: medium.'
  end

  test 'should prevent scaled apps when not enough gears are available' do
    # This space intentionally left blank;
    # Testing this end-to-end would be relatively time consuming right now.
  end

#  test "should check for empty name" do
#    form = get_post_form
#    form[:name]=''
#    post(:create, {:application => form})
#    assert assigns(:application)
#    assert assigns(:application).errors[:name].length > 0
#    assert_response :success
#  end

#  test "should redirect on success" do
#    post(:create, :application => get_post_form)
#    assert assigns(:application)
#    assert assigns(:application).errors.empty?
#    assert_redirected_to :action => 'show'
#    assert_template
#  end

  def get_post_form(name = 'cart!diy-0.1')
    {:name => 'test1', :application_type => name}
  end

end
