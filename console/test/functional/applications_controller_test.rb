require File.expand_path('../../test_helper', __FILE__)

class ApplicationsControllerTest < ActionController::TestCase

  test "should create and delete app" do
    # in applications_controller_sanity_test
  end

  def create_and_destroy(type)
    with_unique_domain
    post(:create, {:application => get_post_form(type)})

    assert app = assigns(:application)
    assert app.errors.empty?, app.errors.inspect

    delete :destroy, :id => app.id
    assert_redirected_to applications_path
  end

  #TODO: more intelligently specify templates to test
  %w(rails drupal wordpress kitchensink).each do |type|
    test "should be able to create application based on #{type} template" do
      create_and_destroy(type)
    end
  end

  test "should create JBoss EAP app" do
    create_and_destroy('jbosseap-6.0')
  end

  test "should assign domain errors on empty name" do
    with_unique_user
    app_params = get_post_form
    post(:create, {:application => app_params})

    assert_template 'application_types/show'
    assert app = assigns(:application)
    assert !app.errors.empty?
    assert app.errors[:domain_name].present?, app.errors.inspect
    assert_equal 1, app.errors[:domain_name].length
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

  test "should assign errors on long name" do
    with_domain
    app_params = get_post_form
    app_params[:name] = 'aoeu'*30
    post(:create, {:application => app_params})

    assert_template 'application_types/show'
    assert app = assigns(:application)
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
    assert !app.errors.empty?
    assert app.errors[:name].present?, app.errors.inspect
    assert_equal 1, app.errors[:name].length, app.errors.inspect
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
    assert groups[0].cartridges.map(&:name).include? with_app.cartridge
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
    assert_equal 1, groups.length
    assert groups[0].cartridges.map(&:name).include? with_scalable_app.cartridge
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
    get :show, :id => 'idontexist'
    assert_response 404
  end

  test "should result in a not found when retrieving a domain that does not exist" do
    with_unique_user
    get :show, :id => 'idontexist'
    assert_response 404
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

  def get_post_form(name = 'diy-0.1')
    {:name => 'test1', :application_type => name}
  end
end
