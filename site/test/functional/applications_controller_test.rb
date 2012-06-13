require File.expand_path('../../test_helper', __FILE__)

class ApplicationsControllerTest < ActionController::TestCase
  def setup
    with_unique_domain
    #@domain.reload.applications.each {|app| app.destroy}
  end

  test "should create and delete app" do
    post(:create, {:application => get_post_form})

    assert app = assigns(:application)
    assert app.errors.empty?, app.errors.inspect

    delete :destroy, :id => app.id
    assert_redirected_to applications_path
  end

  test "should be able to find templates" do
    types = ApplicationType.all :as => @user
    (templates,) = types.partition{|t| t.template}
    assert_not_equal 0, templates.length, "There should be templates to test against"
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

  def create_and_destroy(type)
    post(:create, {:application => get_post_form(type)})

    assert app = assigns(:application)
    assert app.errors.empty?, app.errors.inspect

    delete :destroy, :id => app.id
    assert_redirected_to applications_path
  end

  test "should assign errors on empty name" do
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
    post(:create, {:application => get_post_form})
    app = assigns(:application)
    assert app
    assert app.errors.empty?, app.errors.inspect
    puts app.errors.inspect unless app.errors.empty?

    form = get_post_form
    form[:name] = "test2"
    post(:create, {:application => form})
    app = assigns(:application)
    assert app
    assert app.errors.empty?, app.errors.inspect

    # get a filtered version of the list
    post(:index, :applications_filter => get_filter_form)
    apps = assigns(:applications)
    assert apps
    assert_equal apps.length, 1
    assert_equal apps[0].name, 'test2'
    assert_response :success

    # get full version of the list
    get(:index)
    apps = assigns(:applications)
    assert apps
    assert_equal apps.length, 2
    apps.each do |app|
      assert app.name == 'test1' || app.name == 'test2'
    end
    assert_response :success

    # delete app
    assert_difference('assigns(:applications).count', -1) do
      delete :destroy, :id => 'test2'
      # for some reason the redirect doesn't update applications
      # so we call index here to make sure the app is deleted
      get :index
    end
  end

  test "should retrieve application details" do
    get :show, :id => readable_app.name
    assert_response :success
    assert app = assigns(:application)
    assert_equal readable_app.name, app.name
    assert groups = assigns(:gear_groups)
    assert_equal 1, groups.length
    assert groups[0].cartridges.map(&:name).include? readable_app.cartridge
    assert groups[0].cartridges[0].display_name
    assert domain = assigns(:domain)
    assert !assigns(:has_keys)
  end

  test "should retrieve application details with has_sshkey cache set" do
    session[:has_sshkey] = true
    get :show, :id => readable_app.name
    assert_response :success
    assert app = assigns(:application)
    assert has_keys = assigns(:has_keys)
  end

  test "should retrieve scalable application details" do
    get :show, :id => scalable_app.name
    assert_response :success
    assert app = assigns(:application)
    assert_equal scalable_app.name, app.name
    assert groups = assigns(:gear_groups)
    assert_equal 1, groups.length
    assert groups[0].cartridges.map(&:name).include? scalable_app.cartridge
    assert domain = assigns(:domain)
  end

  test "should retrieve application get started page" do
    get :get_started, :id => readable_app.name
    assert_response :success
    assert app = assigns(:application)
    assert_equal readable_app.name, app.name
  end

  test "should retrieve application delete confirm page" do
    get :delete, :id => readable_app.name
    assert_response :success
    assert app = assigns(:application)
    assert_equal readable_app.name, app.name
  end

  test "should result in a not found error when retrieving and application that does not exist" do
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

  def get_filter_form
    {:name => 'test2'}
  end
end
