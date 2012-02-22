require 'test_helper'

class ApplicationsControllerTest < ActionController::TestCase
#  test "should get new unauthorized" do
#    get :new
#    assert_response :success
#  end

  def setup
    setup_integrated
  end

  def setup_integrated
    host = ENV['LIBRA_HOST'] || 'localhost'
    RestApi::Base.site = "https://#{host}/broker/rest"
    RestApi::Base.prefix='/broker/rest/'

    @ts = "#{Time.now.to_i}#{gen_small_uuid[0,6]}"

    @user = WebUser.new :email_address=>"app_test1@test1.com", :rhlogin=>"app_test1@test1.com"
    auth_headers = {'Authorization' => "Basic #{Base64.encode64("#{@user.login}:#{@user.password}").strip}"}

    domain = Domain.new :namespace => "#{@ts}", :as => @user
    unless domain.save
      puts domain.errors.inspect
      fail 'Unable to create the initial domain, test cannot be run'
    end
    setup_session
  end

  def setup_session
    session[:login] = @user.login
    session[:user] = @user
    session[:ticket] = '123'
    @request.cookies['rh_sso'] = '123'
    @request.env['HTTPS'] = 'on'
  end

  test "should create and delete app" do
    post(:create, {:application => get_post_form})
    app = assigns(:application)
    assert app
    assert app.errors.empty?

    delete :destroy, :id => app.id
    assert_redirected_to applications_path
  end

  test "should retrieve application list" do
    post(:create, {:application => get_post_form})
    app = assigns(:application)
    assert app
    assert app.errors.empty?

    form = get_post_form
    form[:name] = "test2"
    post(:create, {:application => form})
    app = assigns(:application)
    assert app
    assert app.errors.empty?

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
    {:name => 'test1', :application_type => 'raw-0.1'}
  end

  def get_filter_form
    {:name => 'test2'}
  end

  def teardown
    domain = Domain.first :as => @user
    domain.destroy_recursive if domain
  end
end
