require 'test_helper'

class ApplicationsControllerTest < ActionController::TestCase
  def setup
    with_domain
    @domain.reload.applications.each {|app| app.destroy}
  end

  test "should create and delete app" do
    post(:create, {:application => get_post_form})

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
    assert_equal 1, app.errors[:name].length
  end

  test "should assign errors on invalid characters" do
    app_params = get_post_form
    app_params[:name] = '@@ @@'
    post(:create, {:application => app_params})

    assert_template 'application_types/show'
    assert app = assigns(:application)
    assert !app.errors.empty?
    assert app.errors[:name].present?, app.errors.inspect
    assert_equal 1, app.errors[:name].length
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
    post(:create, {:application => get_post_form})
    app = assigns(:application)
    assert app
    assert app.errors.empty?

    get :show, :id => 'test1'
    assert_response :success
    app = assigns(:application)
    app_framework = assigns(:application_type)
    assert app
    assert app_framework
    assert_equal 'test1', app.name
    assert_equal 'diy-0.1', app_framework.id

    app.destroy
  end

  test "should result in a not found error when retrieving and application that does not exist" do
    # FIXME: This should be an 404 error page, not an exception
    assert_raise ActiveResource::ResourceNotFound do
      get :show, :id => 'idontexist'
    end
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

  def get_post_form
    {:name => 'test1', :application_type => 'diy-0.1'}
  end

  def get_filter_form
    {:name => 'test2'}
  end
end
