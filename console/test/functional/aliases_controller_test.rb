require File.expand_path('../../test_helper', __FILE__)

class AliasesControllerTest < ActionController::TestCase

  setup :with_configured_user
  setup do 
    with_app.aliases.each {|a| a.destroy }
  end

  def unique_name_format
    'www.alias%i.com'
  end

  def test_alias
    @test_alias ||= unique_name
  end

  test "should show alias creation form" do
    get :index, :application_id => with_app.name
    assert_response :success
    assert_template :index

    assert app = assigns(:application)
    assert_equal with_app.name, app.name
    assert domain = assigns(:domain)
    assert_equal with_app.domain_id, domain.id

    assert a = assigns(:alias)
    assert_nil a.id
    assert !a.has_private_ssl_certificate?
    assert_nil a.certificate_added_at
    assert !a.persisted?
  end

  test "should create alias without cert" do
    app = with_app
    post :create, {:alias => get_post_form_without_certificate, :application_id => app.name}

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

  test "should delete alias without cert" do
    app = with_app

    a = Alias.new({:id => "www.foo.com"})
    a.application = app
    a.save!

    post :destroy, {:id => a.id, :application_id => app.name}

    assert_redirected_to application_path(app)
    assert flash[:success] =~ /removed/, "Expected a success message"
  end

  test "should show alias information" do
    app = with_app
    an_alias = app.aliases.first || (Alias.create :as => @user, :application_name => app.name, :id => test_alias, :domain_id => app.domain_id)
    an_alias.reload
    get :show, :application_id=>app.name, :id=>an_alias.id
    assert loaded_app = assigns(:application)
    assert_equal loaded_app.name, app.name
    assert loaded_alias = assigns(:alias)
    assert_equal an_alias.id, loaded_alias.id
  end

  test "should assign errors with empty id" do
    app = with_app
    post :create, {:alias => {:id => ''}, :application_id => app.name}

    assert a = assigns(:alias)
    assert !a.errors.empty?
    assert_redirected_to application_aliases_path(app)
  end

  def get_post_form_without_certificate
    id = test_alias
    {:id => id}
  end

  def get_post_form_with_certificate
    get_post_form_without_certificate.merge({
      :certificate_file => fixture_file_upload('cert.crt', 'application/pkix-cert'),
      :certificate_private_key_file => fixture_file_upload('cert_key_rsa', 'application/octet-stream'),
      :certificate_pass_phrase => ''
    })
  end
end

