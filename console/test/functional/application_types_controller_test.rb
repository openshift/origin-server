require File.expand_path('../../test_helper', __FILE__)

class ApplicationTypesControllerTest < ActionController::TestCase

  setup{ Quickstart.reset! }

  test 'should show index with proper title' do
    with_unique_user
    get :index
    assert_response :success
    assert_select 'head title', 'OpenShift Origin'
  end

  test "should show index" do
    RestApi.stubs(:external_cartridges_enabled?).returns(true)

    with_unique_user
    get :index
    assert_response :success
    assert_template :index
    assert groups = assigns(:type_groups)
    assert groups.length > 1, groups.length.to_s
    assert groups.any?{ |g| g[0] == 'Java' }
    assert groups.first[1].present?

    assert_select "input[name='application_type[cartridges]'][type=text]", nil, @response.inspect
    assert_select "p", /Have your own framework/
  end

  test "should be able to find quickstarts" do
    with_unique_user
    types = ApplicationType.all
    (quickstarts,) = types.partition{|t| t.quickstart?}
    omit("No quickstarts have been registered on this server") if quickstarts.empty?
    assert_not_equal 0, quickstarts.length, "There should be quickstarts to test against"
  end

  test "should show empty search results" do
    with_unique_user
    ApplicationType.expects(:search).returns([])
    get :index, :search => 'foo'
    assert_response :success
    assert_template :search
    assert_equal 'foo', assigns(:search)
    assert groups = assigns(:type_groups)
    assert_equal 1, groups.length
    assert_equal "Matches search 'foo'", groups.first[0]
    assert groups.first[1].empty?
    assert tags = assigns(:browse_tags)
    assert tags.present?
    assert tags.first[0].is_a? String
    assert tags.first[1].is_a? Symbol
  end

  def assert_standard_show_type(t)
    assert_response :success
    assert type = assigns(:application_type)
    assert_equal t.display_name, type.display_name
    assert assigns(:application)
    assert assigns(:domain)
    assert css_select('input#application_domain_name').present?
    if t.tags.include?(:not_scalable) or t.id == 'diy-0.1'
      # Sanity-check known non-scalable types
      assert_equal false, t.scalable?
    elsif t.id == 'php-5.3'
      # Sanity-check a known scaling-capable type
      assert_equal true, t.scalable?
    end
  end

  test "should show type page for cartridge" do
    with_unique_user
    type = ApplicationType.all.select{ |t| t.cartridge? }.sample(1).first

    get :show, :id => type.id
    assert_standard_show_type(type)
  end

  test "should show type page for quickstart" do
    with_unique_user
    type = ApplicationType.all.select(&:quickstart?).sample(1).first
    omit("No quickstarts registered on this server") if type.nil?

    get :show, :id => type.id
    assert_standard_show_type(type)
  end

  test "should handle invalid quickstart page" do
    with_unique_user
    type = Quickstart.new(:id => 'test', :name => '', :cartridges => '[{')
    Quickstart.expects(:find).returns(type)

    get :show, :id => 'quickstart!test'
    assert_standard_show_type(type)
  end

  test "should render custom type" do
    with_unique_user
    get :show, :id => 'custom'
    assert_response :success
    assert_select '.alert.alert-error', /No cartridges are defined for this type/i
    assert_select 'h3 > span.text-warning', 'None'
    assert_select '.btn-primary[disabled=disabled]'
    assert_select "input[name='application[initial_git_url]']", 0
  end

  test "should render custom single cart type" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => 'ruby-1.9'
    assert_response :success
    assert_select 'h3', 'Ruby 1.9'
    assert_select 'h3', 'From Scratch'
    assert_select "input[name='application[cartridges][]'][value=ruby-1.9]"
  end

  test "should render custom single cart type with url" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => 'http://foo.bar#custom_cart'
    assert_response :success
    assert_select 'h3', 'From Scratch'
    assert_select 'h3 > a', 'custom_cart'
    assert_select '.text-warning', /Custom cartridges do not receive updates automatically/
    assert_select "input[type=hidden][name='application[cartridges][][url]'][value=http://foo.bar#custom_cart]"
  end

  test "should render custom single cart type with url unlocked" do
    with_unique_user
    get :show, :id => 'custom', :application_type => {:cartridges => 'http://foo.bar#custom_cart'}, :unlock => true
    assert_response :success
    assert_select 'h3', 'From Scratch'
    assert_select '.text-warning', /Custom cartridges do not receive updates automatically/
    assert_select "input[type=text][name='application_type[cartridges]'][value=http://foo.bar#custom_cart]"
  end

  test "should render custom cart type with a choice" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => 'ruby'
    assert_response :success
    assert_select "select[name='application[cartridges][]'] > option", 'Ruby 1.9'
    assert_select "select[name='application[cartridges][]'] > option", 'Ruby 1.8'
  end

  test "should render custom multiple carts" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => ['ruby-1.9', 'mysql-5.1']
    assert_response :success
    assert_select 'h3', /Ruby 1\.9/i
    assert_select 'h3', /MySQL/i
  end

  test "should not render custom valid JSON" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => ['ruby-1.9', 'mysql-5.1'].to_json
    assert_response :success
    assert assigns(:cartridges).blank?
    assert_select '.alert.alert-error', /No cartridges are defined for this type/i
    assert_select 'h3 > span.text-warning', 'None'
  end

  test "should not fail on custom invalid JSON" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => "[{'ruby-1.9'}, {'mysql-5.1'}]"
    assert_response :success
    assert assigns(:cartridges).blank?
    assert_select '.alert.alert-error', /No cartridges are defined for this type/i
    assert_select 'h3 > span.text-warning', 'None'
  end

  test "should render custom initial_git_url" do
    with_unique_user
    get :show,
      :id => 'custom',
      :cartridges => 'ruby-1.9',
      :initial_git_url => 'http://foo.com',
      :initial_git_branch => 'bar'
    assert_response :success
    assert_select 'h3 > a', 'http://foo.com'
    #assert_select 'h3', /branch 'bar'/
  end

  test "should render advanced custom type" do
    with_unique_user
    get :show, :id => 'custom', :advanced => true, :initial_git_url => 'http://foo.com', :initial_git_branch => 'bar'
    assert_response :success
    assert assigns(:advanced)
    assert_select '.alert.alert-error', /No cartridges are defined for this type/i
    assert_select 'h3 > span.text-warning', 'None'
    assert_select '.btn-primary[disabled=disabled]'
    assert_select "select[name='application[scale]']"
    assert_select "input[name='application[initial_git_url]']" do |inputs|
      assert inputs.first['value'] == 'http://foo.com'
    end
    #assert_select "input[name='application[initial_git_branch]']" do |inputs|
    #  assert inputs.first['value'] == 'bar'
    #end
  end

  test "show page should cache user capabilities" do
    # set up the test
    with_user_with_multiple_gear_sizes
    user = User.find(:one, :as => @controller.current_user)
    types = ApplicationType.all
    type = types[0]

    # confirm the session is clear of relevant keys
    assert !session.has_key?(:caps)

    # make the request
    get :show, :id => type.id

    # compare the session cache with expected values
    assert_equal [user.max_gears, user.consumed_gears, user.gear_sizes], Array(session[:caps]).first(3)
    assert_equal user.gear_sizes, assigns(:capabilities).gear_sizes
    assert_equal user.max_gears, assigns(:capabilities).max_gears
    assert_equal user.consumed_gears, assigns(:capabilities).consumed_gears
  end

  test "show page should refresh cached user_capabilities" do
    # set up the test
    with_user_with_multiple_gear_sizes
    user = User.find(:one, :as => @controller.current_user)
    types = ApplicationType.all
    type = types[0]

    # seed the cache with values that will never be returned by the broker.
    session[:caps] = ['test_value','test_value',['test_value','test_value'], 'test_value']

    # make the request
    get :show, :id => type.id

    # confirm that the assigned values match our cached values
    assert_equal [user.max_gears, user.consumed_gears, user.gear_sizes], Array(session[:caps]).first(3)
    assert_equal user.max_gears, assigns(:capabilities).max_gears
    assert_equal user.consumed_gears, assigns(:capabilities).consumed_gears
    assert_equal user.gear_sizes, assigns(:capabilities).gear_sizes
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
    assert_equal t.display_name, type.display_name
    assert assigns(:application)
    assert domain = assigns(:domain)
    assert_equal @domain.id, domain.id
    assert css_select('input#application_domain_name').empty?
  end

  test "should render domain name field" do
    with_unique_user
    get :show, :id => 'custom', :advanced => true, :domain_name => 'TestDomain'

    assert_select 'input#application_domain_name', {:count=>1, :value => 'TestDomain'}
  end

end
