require File.expand_path('../../../test_helper', __FILE__)

module AdminConsole
  class ApplicationsControllerTest < ActionController::TestCase
    def setup    
      @random = rand(1000000000)
      @login = "user#{@random}"
      @password = 'password'
      @user = CloudUser.new(login: @login)
      @user.private_ssl_certificates = true
      @user.save
      Lock.create_lock(@user.id)
      register_user(@login, @password)

      stubber
      @namespace = "ns#{@random}"
      @domain = Domain.new(namespace: @namespace, owner:@user)
      @domain.save
      @app_name = "app#{@random}"
      @app = Application.create_app(@app_name, cartridge_instances_for(:php), @domain)
      @app_alias = Alias.new(fqdn: "app#{@random}.foo.bar")
      @app.aliases.push(@app_alias)
      @app.save
    end

    def teardown
      begin
        @user.force_delete
      rescue
      end
    end

    test "should show application by uuid" do
      get :show, :id => @app.uuid
      assert_response :success
      assert_select 'h1.header', /#{@app.name}/
    end

    test "should show application by name" do
      get :show, :id => @app.name
      assert_response :success
      assert_select 'h1.header', /#{@app.name}/
    end

    test "should show application by fqdn" do
      get :show, :id => @app.fqdn
      assert_response :success
      assert_select 'h1.header', /#{@app.name}/
    end

    test "should show application by alias" do
      get :show, :id => @app_alias.fqdn
      assert_response :success
      assert_select 'h1.header', /#{@app.name}/
    end

    test "should show application not found" do
      app_id = "does_not_exist#{@random}"
      get :show, :id => app_id
      assert_not_found_page "Application #{app_id} not found"
    end
    
  end
end
