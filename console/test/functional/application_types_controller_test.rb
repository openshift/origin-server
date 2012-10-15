require File.expand_path('../../test_helper', __FILE__)

class ApplicationTypesControllerTest < ActionController::TestCase

  test 'should show index with proper title' do
    with_unique_user
    get :index
    assert_response :success
    assert_select 'head title', 'OpenShift Origin'
  end

  test "should show index" do
    with_unique_user
    get :index
    assert_response :success
    assert types = assigns(:framework_types)
    assert types.length > 5
    assert types[0].name
    jboss_eap_seen = false
    types.each do |t|
      # check to make sure JBoss EAP comes before JBoss AS
      if t.id.start_with? 'jbosseap'
        jboss_eap_seen = true
      elsif t.id.start_with? 'jbossas'
        assert jboss_eap_seen, "Backend lists JBoss AS before JBoss EAP - EAP should take precidence"
      end
    end
  end

  test "should be able to find templates" do
    with_unique_user
    types = ApplicationType.all
    (templates,) = types.partition{|t| t.template}
    assert_not_equal 0, templates.length, "There should be templates to test against"
  end

  test "should show type page" do
    with_unique_user
    types = ApplicationType.all

    types.each do |t|
      get :show, :id => t.id
      assert_response :success
      assert type = assigns(:application_type)
      assert_equal t.name, type.name
      assert assigns(:application)
      assert_nil assigns(:domain)
      assert css_select('input#application_domain_name').present?
    end
  end

  test "show page should cache gear sizes and max gears count" do
    # set up the test
    with_gear_size_user
    user = User.find(:one, :as => @controller.current_user)
    types = ApplicationType.all
    type = types[0]

    # confirm the session is clear of relevant keys
    assert session.has_key?(:capabilities_gear_sizes) == false
    assert session.has_key?(:max_gears) == false

    # make the request
    get :show, :id => type.id

    # compare the session cache with expected values
    assert session[:capabilities_gear_sizes] == user.capabilities.gear_sizes
    assert session[:max_gears] == user.max_gears
  end

  test "show page should use cached gear sizes and max gears count" do
    # set up the test
    with_gear_size_user
    types = ApplicationType.all
    type = types[0]

    # seed the cache with values that will never be returned by the broker.
    session[:capabilities_gear_sizes] = ['test_value','test_value']
    session[:max_gears] = -1

    # make the request
    get :show, :id => type.id

    # confirm that the assigned values match our cached values
    assert_equal assigns(:gear_sizes), session[:capabilities_gear_sizes]
    assert_equal assigns(:max_gears), session[:max_gears]
  end

  test "show page should compute used gear count" do
    # set up the test
    with_gear_size_user
    user = User.find(:one, :as => @controller.current_user)
    types = ApplicationType.all
    type = types[0]

    # make the request
    get :show, :id => type.id

    # confirm expected value
    assert_equal assigns(:gears_used), user.consumed_gears
  end

  test "should raise on missing type" do
    with_unique_user
    get :show, :id => 'missing_application_type'
    assert_response :success
    assert_select 'h1', /Application Type 'missing_application_type' does not exist/
  end

  test "should fill domain info" do
    with_unique_user
    with_unique_domain
    t = ApplicationType.all[0]

    get :show, :id => t.id
    assert_response :success
    assert type = assigns(:application_type)
    assert_equal t.name, type.name
    assert assigns(:application)
    assert domain = assigns(:domain)
    assert_equal @domain.id, domain.id
    assert css_select('input#application_domain_name').empty?
  end
end
