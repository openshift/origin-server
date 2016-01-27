require File.expand_path('../../test_helper', __FILE__)

class AliasesControllerTest < ActionController::TestCase

  setup :with_configured_user
  setup do 
    with_app.aliases(true).each {|a| a.destroy }
  end

  def unique_name_format
    'www.alias%i.com'
  end

  def test_alias
    @test_alias ||= unique_name
  end

  def ssl_test_alias
    @ssl_test_alias ||= unique_name
  end

  def with_ssl_app
    use_app(:ssl_app) { Application.new({:name => "sslapp", :cartridge => 'ruby-1.9', :as => new_named_user("user_with_certificate_capabilities@test.com")}) }
  end

  test "should redirect from index when aliases are empty" do
    get :index, :application_id => with_app
    assert_redirected_to new_application_alias_path(with_app)
  end

  test "should render aliases for an app" do
    Alias.new(:id => "www.#{@domain.id}.com", :application => with_app).save!
    get :index, :application_id => with_app
    assert_response :success
    assert assigns(:application)
    assert_select 'h1', /Aliases for/
    with_app.aliases.each{ |a| assert_select 'td > a', a.name }
    assert_select 'td .icon-unlock', 1
  end

  test "should show alias creation form" do
    get :new, :application_id => with_app
    assert_response :success
    assert_template :new

    assert app = assigns(:application)
    assert_equal with_app.name, app.name
    assert_equal with_app.domain_id, app.domain_id

    assert a = assigns(:alias)
    assert_nil a.id
    assert !a.has_private_ssl_certificate?
    assert_nil a.certificate_added_at
    assert !a.persisted?
  end

  test "should create alias without cert" do
    app = with_app
    post :create, {:alias => get_post_form_without_certificate, :application_id => app}

    assert a = assigns(:alias)
    assert_equal a.id, test_alias
    assert !a.has_private_ssl_certificate?
    assert_nil a.certificate_added_at
    assert_nil a.ssl_certificate
    assert_nil a.private_key
    assert_nil a.pass_phrase
    assert a.errors.empty?
    assert_redirected_to application_path(app)
  end

  [{:name => "empty cert file", :cert => "empty.crt", :key => "cert_key_rsa"},
    {:name => "empty key file", :cert => "cert.crt", :key => "empty_cert_key_rsa"},
    {:name => "key file present and nil cert", :key => "cert_key_rsa"},
    {:name => "cert file present and nil key", :cert => "cert.crt"}
  ].each do |files| 
    test "should assign error with #{files[:name]}" do
      app = with_app

      post :create, {:alias => get_post_form_with_certificate(files[:cert], files[:key]), :application_id => app}

      assert a = assigns(:alias)
      assert !a.errors.empty?
      assert_template :new
    end
  end

  test "should create alias with cert" do
    app = with_ssl_app
    @ssl_test_alias = "www.example#{uuid}.com"
    
    assert_difference('Alias.find(:all, :as => @user, :params => {:application_name => app.name, :domain_id => app.domain_id}).length', 1) do
      post :create, {:alias => get_post_form_with_certificate("cert.crt", "cert_key_rsa"), :application_id => app}
    end

    assert a = assigns(:alias)

    assert_equal a.id, ssl_test_alias
    assert a.has_private_ssl_certificate?
    assert a.certificate_added_at
    assert a.errors.empty?
    assert_redirected_to application_path(app)
  end

  test "should delete alias without cert" do
    app = with_app

    a = Alias.new({:id => "www.foo.com"})
    a.application = app
    a.save!

    post :destroy, {:id => a.id, :application_id => app}

    assert_redirected_to application_path(app)
    assert flash[:success] =~ /removed/, "Expected a success message"
  end

  test "should show alias edit form" do
    app = with_app
    app.reload
    an_alias = app.aliases.first || (Alias.create :as => @user, :application_name => app.name, :id => test_alias, :domain_id => app.domain_id)
    an_alias.reload
    get :edit, :application_id=>app, :id=>an_alias.id
    assert loaded_app = assigns(:application)
    assert_equal loaded_app.name, app.name
    assert loaded_alias = assigns(:alias)
    assert_equal an_alias.id, loaded_alias.id
  end

  test "should show alias delete confirmation" do
    app = with_app
    app.reload    
    an_alias = app.aliases.first || (Alias.create :as => @user, :application_name => app.name, :id => test_alias, :domain_id => app.domain_id)
    an_alias.reload
    get :delete, :application_id=>app, :id=>an_alias.id
    assert loaded_app = assigns(:application)
    assert_equal loaded_app.name, app.name
    assert loaded_alias = assigns(:alias)
    assert_equal an_alias.id, loaded_alias.id
  end 

  test "should show edit form from error on edit" do
    app = with_app

    a = Alias.new({:id => test_alias})
    a.application = app
    a.save!

    post :update, {:alias => get_post_form_with_certificate("empty.crt", nil), :id => test_alias, :application_id => app}

    assert a = assigns(:alias)
    assert !a.errors.empty?
    assert_template :edit
  end

  test "should assign errors with empty id" do
    app = with_app
    post :create, {:alias => {:id => ''}, :application_id => app}

    assert a = assigns(:alias)
    assert !a.errors.empty?
    assert_template :new
  end

  [true,false].each do |owner|
    [true,false].each do |domain_has_ssl|
      test "show correct message when domain #{domain_has_ssl ? 'has' : 'does not have'} custom cert capability and user #{owner ? 'is' : 'is not'} the application owner" do
        Domain::Capabilities.any_instance.expects(:private_ssl_certificates).returns(domain_has_ssl)
        Application.any_instance.expects(:owner?).returns(owner) if !domain_has_ssl

        get :new, :application_id => with_app
        assert_response :success
        assert_template :new

        assert_equal domain_has_ssl, assigns(:private_ssl_certificates_supported)
        if domain_has_ssl
          # Should have a cert form
          assert_select '.alert-warning', :count => 0
          assert_select '#certificate_file'
          assert_select '#certificate_file[disabled=disabled]', :count => 0
        elsif owner
          # Should have a message about certs not supported on their account
          assert_select '.alert-warning:content(?)', /Your account.*SSL/
          assert_select '#certificate_file[disabled=disabled]'
        else
          # Should have a message about certs not supported for this application
          assert_select '.alert-warning:content(?)', /SSL.*this application/
          assert_select '#certificate_file[disabled=disabled]'
        end
      end
    end
  end

  def get_post_form_without_certificate (alias_id = test_alias)
    {:id => alias_id}
  end

  def get_post_form_with_certificate (cert_file_name, key_file_name)
    get_post_form_without_certificate(ssl_test_alias).merge({
      :certificate_file => cert_file_name.nil? ? nil : fixture_file_upload(cert_file_name, 'application/pkix-cert'),
      :certificate_private_key_file => key_file_name.nil? ? nil : fixture_file_upload(key_file_name, 'application/octet-stream'),
      :certificate_pass_phrase => ''
    })
  end

end

