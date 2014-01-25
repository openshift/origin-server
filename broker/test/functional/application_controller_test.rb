ENV["TEST_NAME"] = "functional_applications_controller_test"
require_relative '../test_helper'
class ApplicationControllerTest < ActionController::TestCase

  def setup
    Rails.cache.clear
    @controller = allow_multiple_execution(ApplicationsController.new)

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.private_ssl_certificates = true
    @user.capabilities["gear_sizes"] = ['small', 'medium', 'large']
    @user.save
    Lock.create_lock(@user)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    stubber
    @namespace = "ns#{@random}"
    @domain = Domain.new(namespace: @namespace, owner:@user)
    @domain.save
  end

  def teardown
    @user.force_delete rescue nil
  end

  test "app create show list update and destroy by domain and app name" do
    @app_name = "app#{@random}"

    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace, "initial_git_url" => "https://a:b@github.com/foobar/test.git"}
    assert_response :created
    assert app = assigns(:application)
    assert_equal 1, app.gears.length

    get :show, {"id" => @app_name, "domain_id" => @domain.namespace, "include" => "cartridges"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert link = json['data']['links']['ADD_CARTRIDGE']
    assert_equal Rails.configuration.openshift[:download_cartridges_enabled], link['optional_params'].one?{ |p| p['name'] == 'url' }

    assert_equal [@domain.namespace, @app_name, false, 1, 'small', 'https://github.com/foobar/test.git'], json['data'].values_at('domain_id', 'name', 'scalable', 'gear_count', 'gear_profile', 'initial_git_url'), json['data'].inspect

    assert_equal 1, (members = json['data']['members']).length
    assert_equal [@login, true, 'admin', nil, @user._id.to_s, 'user'], members[0].values_at('login', 'owner', 'role', 'explicit_role', 'id', 'type'), members[0].inspect

    assert_equal 1, (carts = json['data']['cartridges']).length
    assert_equal [1, 1, 1, 1, 1, 0], carts[0].values_at('scales_from', 'scales_to', 'supported_scales_to', 'supported_scales_from', 'base_gear_storage', 'additional_gear_storage'), carts[0].inspect

    get :index, {"domain_id" => @domain.namespace}
    assert_response :success

    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace,
                  "auto_deploy" => false,
                  "keep_deployments" => 2,
                  "deployment_type" => 'binary',
                  "deployment_branch" => 'stage'
                 }
    assert_response :success

    get :show, {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    #TODO uncomment once save to mongo is fixed
    assert_equal json['data']['auto_deploy'], false
    assert_equal json['data']['keep_deployments'], 2
    assert_equal json['data']['deployment_type'], 'binary'
    assert_equal json['data']['deployment_branch'], 'stage'


    delete :destroy, {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :ok
  end

  test "app create scalable show destroy by domain and app name" do
    @app_name = "app#{@random}"

    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace, "scale" => true}
    assert_response :created

    get :show, {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :success
    assert app = assigns(:application)
    assert app.scalable

    delete :destroy, {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :ok
  end

  test "app create scalable with different gear types" do
    @app_name = "app#{@random}"

    post :create, {"name" => @app_name, "cartridges" => [
      {"name" => php_version, "gear_size" => "medium", "scales_from" => 2, "scales_to" => 3},
      {"name" => mysql_version, "gear_size" => "medium", "additional_storage" => 2}
    ], "domain_id" => @domain.namespace, "scale" => true}
    assert_response :created

    get :show, {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :success
    assert app = assigns(:application)
    assert app.scalable
    assert_equal 2, app.group_instances.length

    overrides = app.group_instances_with_overrides
    overrides.sort_by{ |i| i.components.length }

    assert_equal 1, overrides[0].min_gears
    assert_equal 1, overrides[0].max_gears
    assert_equal "medium", overrides[0].gear_size
    assert_equal 2, overrides[0].additional_filesystem_gb

    assert_equal 2, overrides[1].min_gears
    assert_equal 3, overrides[1].max_gears
    assert_equal "medium", overrides[1].gear_size
    assert_equal 0, overrides[1].additional_filesystem_gb
  end

  test "set app configuration on create" do
    defaults = {'auto_deploy' => true, 'deployment_branch' => 'master', 'keep_deployments' => 1, 'deployment_type' => 'git'}

    post :create, {"name" => "app#{@random}", "cartridge" => php_version, "domain_id" => @domain.namespace, "config" => {"garbage" => 1}}
    assert_response :created
    assert app = assigns(:application)
    assert app.reload.config["auto_deploy"]
    assert_nil app.config["garbage"]

    # send valid values
    post :create, {"name" => "app#{@random}1", "cartridge" => php_version, "domain_id" => @domain.namespace, "config" => {
      "auto_deploy" => "false",
      "deployment_branch" => "stage",
      "keep_deployments" => "2",
      "deployment_type" => "binary",
    }}
    assert_response :created
    assert app = assigns(:application)
    assert_equal defaults.merge('auto_deploy' => false, 'deployment_branch' => "stage", "keep_deployments" => 2, "deployment_type" => 'binary'), app.reload.config

    # send invalid values
    post :create, {"name" => "app#{@random}2", "cartridge" => php_version, "domain_id" => @domain.namespace, "config" => {
      "auto_deploy" => "x",
      "deployment_branch" => nil,
      "keep_deployments" => "x",
      "deployment_type" => "foo",
    }}
    assert_response :unprocessable_entity
    assert app = assigns(:application)
    assert !app.persisted?
    assert app.errors[:config].present?
    messages = app.errors.full_messages
    assert_equal 2, messages.length, messages.inspect
    assert messages.any?{ |m| m =~ /Invalid value 'x' for auto_deploy/ }, app.errors.inspect
    assert messages.any?{ |m| m =~ /Invalid deployment type: foo/ }, app.errors.inspect
  end

  test "create domain during app create" do
    @app_name = "app#{@random}"
    @domain.destroy
    @user.max_domains = 1
    @user.save

    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @namespace}
    assert_response :created

    assert @user.domains.first
    assert_equal @namespace, @user.domains.first.namespace

    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => "#{@namespace}1"}
    assert_response :conflict
    assert json = JSON.parse(response.body)
    assert_equal 'domain_id', json['messages'][0]['field']
    assert json['messages'][0]['text'].include?("You may not have more than 1 domain."), json['messages'].inspect
    assert_equal 103, json['messages'][0]['exit_code']
  end

  test "app create available show destroy by domain and app name" do
    @app_name = "app#{@random}"

    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace, "ha" => true}
    assert_response :created

    get :show, {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :success
    assert app = assigns(:application)
    assert app.scalable
    assert app.ha
    assert_equal 2, app.gears.length

    delete :destroy, {"id" => @app_name, "domain_id" => @domain.namespace}
    assert_response :ok
  end

  test "app create show list and destroy by app id" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert link = json['data']['id']
    app_id =  json['data']['id']

    get :show, {"id" => app_id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert link = json['data']['links']['ADD_CARTRIDGE']
    assert_equal Rails.configuration.openshift[:download_cartridges_enabled], link['optional_params'].one?{ |p| p['name'] == 'url' }

    get :index
    assert_response :success

    delete :destroy , {"id" => app_id}
    assert_response :ok
  end

  test "list applications in a non-lowercased domain" do
    Domain.find_or_create_by(namespace: "abcD", owner: @user)
    get :index, :domain_id => 'abcD'
    assert_response :success
  end

  test "attempt to create and update without create_application permission" do
    @app_name = "app#{@random}"
    scopes = Scope::Scopes.new
    CloudUser.any_instance.stubs(:scopes).returns(scopes << Scope::Read.new)
    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :forbidden

    @app_name = "app#{@random}"
    scope = Scope::Session.new
    scope.expects(:authorize_action?).at_least(3).returns(false)
    scopes.clear << scope

    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :forbidden

    scopes.clear << Scope::Session.new
    @domain.members.find(@user).role = :view
    @domain.save; @domain.run_jobs

    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :forbidden

    @domain.members.find(@user).role = :edit
    @domain.save; @domain.run_jobs

    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :success

    scopes.clear << Scope::Session.new
    @domain.members.find(@user).role = :view
    @domain.save; @domain.run_jobs

    put :update, {"name" => @app_name, "domain_id" => @domain.namespace, "auto_deploy" => false}
    assert_response :forbidden

    @domain.members.find(@user).role = :edit
    @domain.save; @domain.run_jobs

    put :update, {"name" => @app_name, "domain_id" => @domain.namespace, "auto_deploy" => false}
    assert_response :success
  end

  test "attempt to create with only build scope" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :created
    app = assigns(:application)

    CloudUser.any_instance.stubs(:scopes).returns(Scope::Scopes.new << Scope::DomainBuilder.new(app))

    # allows creation of a builder
    @app_name = "appx#{@random}"
    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :created
    builder_app = assigns(:application)
    # records that the builder is associated
    assert_equal builder_app.builder_id, app._id
    assert_equal builder_app.builder, app
  end

  test "create strips sensitive data from initial_git_url" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => php_version, "initial_git_url" => 'https://foo:bar@test.com', "domain_id" => @domain.namespace}
    assert_response :created
    app = assigns(:application)
    assert_equal 'https://test.com', app.init_git_url
  end

  test "attempt to create when all gear sizes are disabled" do
    Domain.any_instance.stubs(:allowed_gear_sizes).returns([])

    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :forbidden
    assert json = JSON.parse(response.body)
    assert_nil json['messages'][0]['field']
    assert json['messages'][0]['text'] =~ /disabled all gear sizes from being created/
    assert_equal 134, json['messages'][0]['exit_code']
  end

  test "invalid or empty app name or id" do
    # no name
    post :create, {"domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    # name with dashes
    post :create, {"domain_id" => @domain.namespace, "name" => "abcd-1234", "cartridge" => php_version}
    assert_response :unprocessable_entity
    # name already exists
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :created
    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity

    get :show, {"domain_id" => @domain.namespace}
    assert_response :not_found
    get :show
    assert_response :not_found
    delete :destroy , {"domain_id" => @domain.namespace}
    assert_response :not_found
    delete :destroy
    assert_response :not_found
  end

  test "no domain id" do
    @app_name = "app#{@random}"
    post :create, {"id" => @app_name}
    assert_response :not_found
    get :show, {"id" => @app_name}
    assert_response :not_found
    delete :destroy , {"id" => @app_name}
    assert_response :not_found
  end

  test "no web_framework cartridge or too many" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    post :create, {"name" => @app_name, "cartridges" => "mysql-5.1", "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    post :create, {"name" => @app_name, "cartridges" => [php_version, "ruby-1.9"], "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
  end

  test "invalid updates" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :created

    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace
                 }
    assert_response :unprocessable_entity

    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace,
                  "auto_deploy" => 'blah'
                 }
    assert_response :unprocessable_entity

    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace,
                  "keep_deployments" => 'blah'
                 }
    assert_response :unprocessable_entity

    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace,
                  "deployment_type" => 'blah'
                 }
    assert_response :unprocessable_entity

    put :update, {"id" => @app_name,
                  "domain_id" => @domain.namespace,
                  "deployment_branch" => 'a'*257
                  }
    assert_response :unprocessable_entity

    # See git-check-ref-format man page for rules
    invalid_values = ["abc.lock", "abc/.xyz", "abc..xyz", "/abc", "abc/", "abc//xyz", "abc.", "abc@{xyz}"]
    invalid_chars = ["^", "~", ":", "?", "*", "\\", " ", "[", ";"]
    invalid_chars.each do |invalid_char|
      invalid_values.push("abc#{invalid_char}xyz")
    end
    invalid_values.each do |invalid_value|
      put :update, {"id" => @app_name,
                    "domain_id" => @domain.namespace,
                    "deployment_branch" => invalid_value
                   }
      assert_response :unprocessable_entity, "Expected value ref:#{invalid_value} to be rejected"
    end
  end

  test "get application in all version" do
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => php_version, "domain_id" => @domain.namespace}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"id" => @app_name, "domain_id" => @domain.namespace}
      assert_response :ok, "Getting application for version #{version} failed"
    end
  end

  test "attempt to create an application with obsolete cartridge" do
    begin
      carts = []
      cart = OpenShift::Cartridge.new
      cart.cartridge_vendor = "redhat"
      cart.name = "ruby-1.8"
      cart.provides = ["ruby"]
      cart.version = "1.8"
      cart.categories = ['web_framework']
      cart.obsolete = true

      carts << cart
      cart = OpenShift::Cartridge.new
      cart.cartridge_vendor = "redhat"
      cart.name = "ruby-1.9"
      cart.provides = ["ruby"]
      cart.version = "1.9"
      cart.categories = ['web_framework']
      carts << cart

      cart = OpenShift::Cartridge.new
      cart.cartridge_vendor = "other"
      cart.name = "ruby-1.10"
      cart.provides = ["ruby"]
      cart.version = "1.10"
      cart.categories = ['web_framework']
      carts << cart
      CartridgeCache.stubs(:get_all_cartridges).returns(carts)

      os = Rails.configuration.openshift
      Rails.configuration.stubs(:openshift).returns(os.merge(:allow_obsolete_cartridges => false))

      @app_name = "app#{@random}"
      post :create, {"name" => @app_name, "cartridge" => "ruby-1.8", "domain_id" => @domain.namespace}
      # CHANGED: This is now allowed - deactivate the cart otherwise.
      assert_response :created
    ensure
      Rails.cache.clear
    end
  end

  def assert_invalid_manifest
    post :create, {"name" => "app#{@random}", "cartridge" => [{"url" => "manifest://test"}], "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    assert json = JSON.parse(response.body)
    assert messages = json['messages']
    messages
  end

  test "create empty downloadable cart" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      MANIFEST
    messages = assert_invalid_manifest
    assert messages.one?{ |m| m['text'] == "The provided downloadable cartridge 'manifest://test' cannot be loaded: Version is a required element" }, messages.inspect
  end

  test "create invalid downloadable cart" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      MANIFEST
    messages = assert_invalid_manifest
    assert messages.one?{ |m| m['text'] == "The provided downloadable cartridge 'manifest://test' cannot be loaded: Version is a required element" }, messages.inspect
  end

  test "create downloadable cart without vendor" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Cartridge-Short-Name: MOCK
      Display-Name: Mock Cartridge 0.1
      Description: A mock cartridge for development use only.
      Version: '0.1'
      Categories:
      - mock
      - web_framework
      MANIFEST
    messages = assert_invalid_manifest
    assert messages.one?{ |m| m['text'] =~ %r(The provided downloadable cartridge 'manifest://test' cannot be loaded.+Cartridge-Vendor '' does not match) }, messages.inspect
  end

  test "create downloadable cart without version" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Cartridge-Short-Name: MOCK
      MANIFEST
    messages = assert_invalid_manifest
    assert messages.one?{ |m| m['text'] =~ %r(The provided downloadable cartridge 'manifest://test' cannot be loaded.+Version is a required element) }, messages.inspect
  end

  test "create downloadable cart without name" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Version: '0.1'
      Cartridge-Short-Name: MOCK
      MANIFEST
    messages = assert_invalid_manifest
    assert messages.one?{ |m| m['text'] =~ %r(The provided downloadable cartridge 'manifest://test' cannot be loaded.+Name is a required element) }, messages.inspect
  end

  test "create downloadable cart with reserved name" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: git
      Version: '0.1'
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: redhat
      MANIFEST
    messages = assert_invalid_manifest
    assert messages.one?{ |m| m['text'] =~ %r(The provided downloadable cartridge 'manifest://test' cannot be loaded.+Name 'git' is reserved\.) }, messages.inspect
  end

  test "create downloadable cart without categories" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      MANIFEST
    messages = assert_invalid_manifest
    assert messages.one?{ |m| m['text'] =~ %r(None of the specified cartridges is a web cartridge) }, messages.inspect
  end

  test "allow create obsolete downloadable cart" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Obsolete: true
      Categories:
      - web_framework
      MANIFEST
    @app_name = "app#{@random}"
    os = Rails.configuration.openshift
    Rails.configuration.stubs(:openshift).returns(os.merge(:allow_obsolete_cartridges => true))
    post :create, {"name" => @app_name, "cartridge" => [{"url" => "manifest://test"}], "domain_id" => @domain.namespace}
    assert_response :created
  end

  test "prevent create obsolete downloadable cart" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Obsolete: true
      Categories:
      - web_framework
      MANIFEST
    @app_name = "app#{@random}"
    os = Rails.configuration.openshift
    Rails.configuration.stubs(:openshift).returns(os.merge(:allow_obsolete_cartridges => false))
    post :create, {"name" => @app_name, "cartridge" => [{"url" => "manifest://test"}], "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    assert json = JSON.parse(response.body)
    assert messages = json['messages']
    assert messages.one?{ |m| m['text'] =~ %r(The cartridge.*is no longer available to be added to an application) }, messages.inspect
  end

  test "prevent create cart with multiple components" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Categories:
      - web_framework
      Components:
        framework1:
        framework2:
      MANIFEST
    @app_name = "app#{@random}"
    os = Rails.configuration.openshift
    post :create, {"name" => @app_name, "cartridge" => [{"url" => "manifest://test"}], "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    assert json = JSON.parse(response.body)
    assert messages = json['messages']
    assert messages.one?{ |m| m['text'].include? "The cartridge mock-mock-0.1 is invalid: only one component may be defined per cartridge." }, messages.inspect
  end

  test "create cart without specified version" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Obsolete: true
      Categories:
      - web_framework
      MANIFEST
    post :create, {"name" => "app#{@random}", "cartridge" => [{"url" => "manifest://test", "version" => "0.2"}], "domain_id" => @domain.namespace}
    assert_response :unprocessable_entity
    assert json = JSON.parse(response.body)
    assert messages = json['messages']
    assert messages.one?{ |m| m['text'] =~ %r(The cartridge 'manifest://test' does not define a version '0\.2'\.) }, messages.inspect
  end

  test "create downloadable cart" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Categories:
      - mock
      - web_framework
      MANIFEST
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => [{"url" => "manifest://test"}], "domain_id" => @domain.namespace, "include" => "cartridges"}
    assert_response :created

    assert json = JSON.parse(response.body)
    assert cart = json['data']['cartridges'].first
    assert_equal ["mock-mock-0.1", "0.1", "manifest://test"], cart.values_at('name', "version", 'url'), json.inspect
    assert_equal [1, 1, 1, 1, 1, 0], cart.values_at('scales_from', 'scales_to', 'supported_scales_from', 'supported_scales_to', 'base_gear_storage', 'additional_gear_storage'), json.inspect

    assert app = assigns(:application)

    app.reload
    assert_nil app.downloaded_cart_map
    # assert carts = app.downloaded_cart_map
    # assert carts.length == 1
    # assert cart = carts['mock']
    # assert_equal "mock-mock-0.1", cart['versioned_name']
    # assert_equal "0.1", cart['version']
    # assert_equal "manifest://test", cart['url']
    # type = OpenShift::Cartridge.new.from_descriptor(YAML.load(cart['original_manifest']))
    # assert_equal ['mock', 'web_framework'], type.categories.sort
    # assert_equal 'Mock Cart', type.display_name

    assert instances = app.component_instances
    assert instances.length == 1
    assert instance = instances[0]
    assert_equal 'manifest://test', instance.manifest_url
    assert_equal 'mock-mock-0.1', instance.cartridge_name
    assert_nil instance.cartridge_id

    type = OpenShift::Cartridge.new.from_descriptor(YAML.load(instance.manifest_text))
    assert_equal instance._id.to_s, type.id
    assert_equal ['mock', 'web_framework'], type.categories.sort
    assert_equal 'Mock Cart', type.display_name
    assert instance_cart = instance.cartridge

    assert carts = app.downloaded_cartridges
    assert carts.length == 1
    assert cart = carts[0]
    assert_same instance_cart, cart
    assert_equal ['mock', 'web_framework'], cart.categories.sort
    assert_equal 'Mock Cart', cart.display_name
    assert_equal "manifest://test", cart.manifest_url
  end

  test "legacy downloadable cart gets carts migrated" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Categories:
      - mock
      - web_framework
      MANIFEST
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => [{"url" => "manifest://test"}], "domain_id" => @domain.namespace, "include" => "cartridges"}
    assert_response :created

    # reset the application to a pre migration state
    assert app = assigns(:application).reload
    cart = app.downloaded_cartridges.first
    app.downloaded_cart_map = {cart.original_name => CartridgeCache.cartridge_to_data(cart)}
    instance = app.component_instances[0]
    instance.cartridge_id = nil
    instance.manifest_url = nil
    instance.manifest_text = nil
    app.save!

    assert cart = app.cartridges.detect{ |i| i.name == 'mock-mock-0.1' }
    assert_equal 'manifest://test', cart.manifest_url

    #$stop = 1
    app.add_cartridges(cartridge_instances_for(:mysql))

    assert instances = app.component_instances
    assert instances.length == 2
    assert instance = instances.detect{ |i| i.cartridge_name == 'mock-mock-0.1' }
    assert_equal 'manifest://test', instance.manifest_url
    type = OpenShift::Cartridge.new.from_descriptor(YAML.load(instance.manifest_text))
    assert_equal instance._id.to_s, type.id
    assert_equal ['mock', 'web_framework'], type.categories.sort
    assert_equal 'Mock Cart', type.display_name
    downloaded = instance.cartridge

    assert instance = instances.detect{ |i| i.cartridge_name == mysql_version }
    assert_nil instance.manifest_url
    assert_nil instance.manifest_text
    assert_not_equal instance._id.to_s, instance.cartridge_id
    assert instance.cartridge_id
    assert_equal 'redhat', instance.cartridge_vendor
    assert type = CartridgeType.find(instance.cartridge_id)
    assert_equal type._id, instance.cartridge_id
    assert_same instance.cartridge, instance.cartridge

    assert carts = app.downloaded_cartridges
    assert carts.length == 1
    assert cart = carts[0]
    assert_same downloaded, cart
    assert_equal ['mock', 'web_framework'], cart.categories.sort
    assert_equal 'Mock Cart', cart.display_name
    assert_equal "manifest://test", cart.manifest_url
  end

  test "create downloadable cart with multiple versions" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Versions: ['0.2']
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Categories:
      - mock
      - web_framework
      Version-Overrides:
        '0.2':
          Display-Name: Mock Cart 2
      MANIFEST
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => [{"url" => "manifest://test"}], "domain_id" => @domain.namespace}
    assert_response :created
    assert app = assigns(:application)
    app.reload
    assert carts = app.downloaded_cartridges
    assert carts.length == 1
    assert cart = carts[0]
    assert_equal ['mock', 'web_framework'], cart.categories.sort
    assert_equal 'Mock Cart', cart.display_name
  end

  test "create downloadable cart with version" do
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(<<-MANIFEST.strip_heredoc)
      ---
      Name: mock
      Version: '0.1'
      Versions: ['0.2']
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Categories:
      - mock
      - web_framework
      Version-Overrides:
        '0.2':
          Display-Name: Mock Cart 2
      MANIFEST
    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => [{"url" => "manifest://test", "version" => "0.2"}], "domain_id" => @domain.namespace}
    assert_response :created
    assert app = assigns(:application)
    app.reload
    assert carts = app.downloaded_cartridges
    assert carts.length == 1
    assert cart = carts[0]
    assert_equal ['mock', 'web_framework'], cart.categories.sort
    assert_equal 'Mock Cart 2', cart.display_name
  end

  test "create downloadable cart from CartridgeType" do
    body = <<-MANIFEST.strip_heredoc
      ---
      Name: remotemock
      Version: '0.1'
      Display-Name: Mock Cart
      Cartridge-Short-Name: MOCK
      Cartridge-Vendor: mock
      Categories:
      - mock
      - web_framework
      MANIFEST
    CartridgeCache.expects(:download_from_url).with("manifest://test", "cartridge").returns(body)
    CartridgeType.where(:base_name => 'remotemock').delete
    types = CartridgeType.update_from(OpenShift::Runtime::Manifest.manifests_from_yaml(body), 'manifest://test')
    types.each(&:activate!)

    @app_name = "app#{@random}"
    post :create, {"name" => @app_name, "cartridge" => ["mock-remotemock-0.1"], "domain_id" => @domain.namespace}
    assert_response :created
    assert app = assigns(:application)
    app.reload
    assert carts = app.downloaded_cartridges
    assert carts.length == 1
    assert cart = carts[0]
    assert_equal ['mock', 'web_framework'], cart.categories.sort
    assert_equal 'Mock Cart', cart.display_name
  end
end
