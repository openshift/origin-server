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
      if t.tags.include?(:template) or t.id == 'diy-0.1'
        # Sanity-check known non-scalable types
        assert_equal false, t.scalable?
      elsif t.id == 'php-5.3'
        # Sanity-check a known scaling-capable type
        assert_equal true, t.scalable?
      end
    end
  end

  test "show page should cache user capabilities" do
    # set up the test
    with_user_with_multiple_gear_sizes
    user = User.find(:one, :as => @controller.current_user)
    types = ApplicationType.all
    type = types[0]

    # confirm the session is clear of relevant keys
    assert session.has_key?(:user_capabilities) == false

    # make the request
    get :show, :id => type.id

    # compare the session cache with expected values
    assert session[:user_capabilities] == [user.max_gears, user.consumed_gears, user.capabilities.gear_sizes]
    assert_equal assigns(:gear_sizes), user.capabilities.gear_sizes
    assert_equal assigns(:max_gears), user.max_gears
    assert_equal assigns(:gears_used), user.consumed_gears
  end

  test "show page should refresh cached user_capabilities" do
    # set up the test
    with_user_with_multiple_gear_sizes
    user = User.find(:one, :as => @controller.current_user)
    types = ApplicationType.all
    type = types[0]

    # seed the cache with values that will never be returned by the broker.
    session[:user_capabilities] = ['test_value','test_value',['test_value','test_value']]

    # make the request
    get :show, :id => type.id

    # confirm that the assigned values match our cached values
    assert session[:user_capabilities] == [user.max_gears, user.consumed_gears, user.capabilities.gear_sizes]
    assert_equal assigns(:gear_sizes), user.capabilities.gear_sizes
    assert_equal assigns(:max_gears), user.max_gears
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
