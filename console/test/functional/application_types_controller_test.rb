require File.expand_path('../../test_helper', __FILE__)

class ApplicationTypesControllerTest < ActionController::TestCase

  with_clean_cache

  setup{ Quickstart.reset! }

  test 'should show index with proper title' do
    with_unique_user
    get :index
    assert_response :success
    assert_select 'head title', 'OpenShift Origin'
  end

  test "should show index" do
    RestApi.stubs(:download_cartridges_enabled?).returns(true)

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

  test "should always show DIY cart" do
    RestApi.stubs(:download_cartridges_enabled?).returns(false)

    with_unique_user
    get :index
    assert_select "a", /Do-It-Yourself/
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
    assert assigns(:domains)
    assert css_select('input#application_domain_name').present?
    if t.id == 'diy-0.1'
      # Sanity-check known non-scalable types
      assert_equal false, t.scalable?
    elsif t.id == 'php-5.3' or t.source == :quickstart
      # Sanity-check a known scaling-capable type
      assert_equal true, t.scalable?
    end
  end

  def assert_hidden_domain_field(value)
    assert_response :success
    assert assigns(:domains)
    assert input = css_select('input[type=hidden]#application_domain_name').first
    assert_equal value.to_s, input.attributes["value"].to_s
  end
  def assert_text_domain_field(value)
    assert_response :success
    assert assigns(:domains)
    assert input = css_select('input[type=text]#application_domain_name').first
    assert_equal value.to_s, input.attributes["value"].to_s
  end
  def assert_select_domain_field(value)
    assert_response :success
    assert assigns(:domains)
    assert select = css_select('select#application_domain_name').first

    selected = ""
    if option = css_select('select#application_domain_name option[selected=selected]').first
      selected = option.attributes["value"]
    end

    assert_equal value.to_s, selected.to_s
  end

  def random_application_type_id
    ApplicationType.all.select{ |t| t.cartridge? }.sample(1).first.id
  end


  test "should show text field for domain with no default" do
    with_unique_user
    get :show, :id => random_application_type_id
    assert_text_domain_field("")
  end

  test "should show text field for domain with prefilled value" do
    with_unique_user
    get :show, {:id => random_application_type_id, :application => {:domain_name => "foo"}}
    assert_text_domain_field("foo")
  end

  test "should show select field with no default for domain for shared domains" do
    with_unique_user
    Domain.expects(:find).returns([ writeable_domain("shared") ])
    get :show, :id => random_application_type_id
    assert_select_domain_field("")
  end

  test "should show select field with prefilled value for domain for shared domains" do
    with_unique_user
    Domain.expects(:find).returns([ writeable_domain("shared") ])
    get :show, {:id => random_application_type_id, :application => {:domain_name => "shared"}}
    assert_select_domain_field("shared")
  end

  test "should show select field with default for domain for owned and shared domains" do
    with_unique_user
    Domain.expects(:find).returns([ owned_domain("owned"), writeable_domain("shared") ])
    get :show, :id => random_application_type_id
    assert_select_domain_field("owned")
  end

  test "should show select field with prefilled value for domain for owned and shared domains" do
    with_unique_user
    Domain.expects(:find).returns([ owned_domain("owned"), writeable_domain("shared") ])
    get :show, {:id => random_application_type_id, :application => {:domain_name => "shared"}}
    assert_select_domain_field("shared")
  end

  test "should show hidden field for domain with owned domain" do
    with_unique_user
    Domain.expects(:find).returns([ owned_domain("owned") ])
    User.any_instance.expects(:max_domains).returns(2)
    get :show, {:id => random_application_type_id}
    assert_hidden_domain_field("owned")
    assert css_select("a.create_domain").present?
  end

  test "should show hidden field for domain with shared domain when cant create" do
    user = with_unique_user
    Domain.expects(:find).returns([ writeable_domain("shared") ])
    User.any_instance.expects(:max_domains).returns(0)
    get :show, {:id => random_application_type_id}
    assert_hidden_domain_field("shared")
    assert_equal [], css_select("a.create_domain")
  end

  def owned_domain(name="owned")
    Domain.new({
      :name => name, 
      :api_identity_id => 'me',
      :members => [
        Member.new(:owner => true, :role => 'admin', :id => 'me')
      ],
      :as => @controller.current_user,
      :gear_counts => {},
      :allowed_gear_sizes => [:small],
      :available_gears => 3
    }, true)
  end

  def writeable_domain(name="shared")
    Domain.new({
      :name => name, 
      :api_identity_id => 'me',
      :members => [
        Member.new(:owner => true,  :role => 'admin', :id => 'you'),
        Member.new(:owner => false, :role => 'admin', :id => 'me')
      ],
      :as => @controller.current_user,
      :gear_counts => {},
      :allowed_gear_sizes => [:small],
      :available_gears => 3
    }, true)
  end

  def readable_domain(name="readable")
    Domain.new({
      :name => name, 
      :api_identity_id => 'me',
      :members => [
        Member.new(:owner => true,  :role => 'admin', :id => 'you'),
        Member.new(:owner => false, :role => 'read',  :id => 'me')
      ],
      :as => @controller.current_user,
      :gear_counts => {},
      :allowed_gear_sizes => [:small],
      :available_gears => 3
    }, true)
  end

  test "should show type page for cartridge" do
    with_unique_user
    type = ApplicationType.all.select{ |t| t.cartridge? }.sample(1).first

    get :show, :id => type.id
    assert_standard_show_type(type)
    assert assigns(:application).name
    assert assigns(:suggesting_name)
  end

  test "should show type page for quickstart" do
    with_unique_user
    type = ApplicationType.all.select(&:quickstart?).sample(1).first
    omit("No quickstarts registered on this server") if type.nil?

    get :show, :id => type.id
    assert_standard_show_type(type)
    assert assigns(:application).name
    assert assigns(:suggesting_name)
  end

  test "should handle invalid quickstart page" do
    with_unique_user
    type = Quickstart.new(:id => 'test', :name => '', :cartridges => '[{')
    Quickstart.cached.expects(:find).returns(type)
    type = ApplicationType.from_quickstart(type)
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
    assert_select "input[name='application[initial_git_url]']"
    assert_select ".indicator-gear-increase", "+1"
  end

  test "should render custom single cart type" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => 'ruby-1.9'
    assert_response :success
    assert_select 'h3', 'Ruby 1.9'
    assert_select 'h3', 'From Scratch'
    assert_select "input[name='application[cartridges][]'][value=ruby-1.9]"
    assert_select ".indicator-gear-increase", "+1"
    assert_equal "ruby", assigns(:application).name
    assert assigns(:suggesting_name)
  end

  test "should render custom single cart type with url" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => 'http://foo.bar#custom_cart'
    assert_response :success
    assert_select 'h3', 'From Scratch'
    assert_select 'h3 > a', 'custom_cart'
    assert_select '.text-warning', /Downloaded cartridges do not receive updates automatically/
    assert_select "input[type=hidden][name='application[cartridges][][url]'][value=http://foo.bar#custom_cart]"
    assert_select ".indicator-gear-increase", "+1"
    assert_equal "customcart", assigns(:application).name
    assert assigns(:suggesting_name)
  end

  test "should render custom single cart type with url unlocked" do
    with_unique_user
    get :show, :id => 'custom', :application_type => {:cartridges => 'http://foo.bar#custom_cart'}, :scale => true, :unlock => true
    assert_response :success
    assert_select 'h3', 'From Scratch'
    assert_select '.text-warning', /Downloaded cartridges do not receive updates automatically/
    assert_select "input[type=text][name='application_type[cartridges]'][value=http://foo.bar#custom_cart]"
    assert_select ".indicator-gear-increase", /\+1\-\?\s+\$/
    assert_nil assigns(:application).name
    assert_nil assigns(:suggesting_name)
  end

  test "should render custom cart type with a choice" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => 'ruby'
    assert_response :success

    assert_select "select[name='application[cartridges][]'] > option", 'Ruby 1.9'
    assert_select "select[name='application[cartridges][]'] > option", 'Ruby 1.8'
    assert_select ".indicator-gear-increase", "+1"
    assert_equal "ruby", assigns(:application).name
    assert assigns(:suggesting_name)
  end

  test "should render custom multiple carts" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => ['ruby-1.9', 'mysql-5.1']
    assert_response :success
    assert_select 'h3', /Ruby 1\.9/i
    assert_select 'h3', /MySQL/i
    assert_select ".indicator-gear-increase", "+1"
  end

  test "should render custom multiple carts scaled" do
    with_unique_user
    get :show, :id => 'custom', :cartridges => ['ruby-1.9', 'mysql-5.1'], :scale => true
    assert_response :success
    assert_select 'h3', /Ruby 1\.9/i
    assert_select 'h3', /MySQL/i
    assert_select ".indicator-gear-increase", "+2"
  end

  test "should render custom multiple carts with alternate params" do
    with_unique_user
    get :show, :id => 'custom', :application => {:cartridges => ['ruby-1.9', 'mysql-5.1'], :scale => true}
    assert_response :success
    assert_select 'h3', /Ruby 1\.9/i
    assert_select 'h3', /MySQL/i
    assert_select ".indicator-gear-increase", "+2"
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
    assert_select "input[type='text'][value='http://foo.com']"
    #assert_select 'h3', /branch 'bar'/
  end

  test "should render advanced custom type" do
    with_unique_user
    get :show, :id => 'custom', :initial_git_url => 'http://foo.com', :initial_git_branch => 'bar'
    assert_response :success
    assert_select '.alert.alert-error', /No cartridges are defined for this type/i
    assert_select 'h3 > span.text-warning', 'None'
    assert_select '.btn-primary[disabled=disabled]'
    assert_select "select[name='application[scale]']"
    assert_select "input[name='application[initial_git_url]'][value='http://foo.com']"
    assert_nil assigns(:application).name
    assert_nil assigns(:suggesting_name)
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
    assert_equal [user.max_domains, user.max_gears, user.consumed_gears, user.gear_sizes], Array(session[:caps])[1..4]
    assert_equal user.max_domains, assigns(:capabilities).max_domains
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
    session[:caps] = [-1, 'test_value', 'test_value','test_value',['test_value','test_value'], 'test_value']

    # make the request
    get :show, :id => type.id

    # confirm that the assigned values match our cached values
    assert_equal [user.max_domains, user.max_gears, user.consumed_gears, user.gear_sizes], Array(session[:caps])[1..4]
    assert_equal user.max_domains, assigns(:capabilities).max_domains
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
    assert domains = assigns(:domains)
    assert domain = domains.first
    assert_equal @domain.id, domain.id
    assert css_select('input#application_domain_name[type=hidden]').present?, response.body
  end

  test "should show estimate for existing domain" do
    with_unique_user
    with_unique_domain
    get :estimate, {:id => 'custom', :application => {:scale => 'false', :domain_name => @domain.id}}
    assert_response :success
    assert css_select('span.indicator-gear-increase').present?, response.body
    assert css_select('span[title*="This will add 1 gear to your account"]').present?, response.body
  end

  test "should show estimate for new domain" do
    with_unique_user
    get :estimate, {:id => 'custom', :application => {:scale => 'true', :domain_name => 'newdomain'}}
    assert_response :success
    assert css_select('span.indicator-gear-increase').present?, response.body
    assert css_select('span[title*="This will add at least 1 gear to your account"]').present?, response.body
  end

  test "should render domain name field" do
    with_unique_user
    get :show, :id => 'custom', :domain_name => 'TestDomain'

    assert_select 'input#application_domain_name', {:count=>1, :value => 'TestDomain'}
  end

end
