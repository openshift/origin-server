ENV["TEST_NAME"] = "functional_regions_controller_test"
require 'test_helper'
class RegionsControllerTest < ActionController::TestCase

  def setup
    @random = rand(1000000000)
    @region = Region.create("region_#{@random}")
    @controller = RegionsController.new
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.private_ssl_certificates = true
    @user.save
    Lock.create_lock(@user.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
  end

  def teardown
    begin
      @region.delete
    rescue
    end
  end

  test "list and show regions" do
    get :index
    assert_response :success
    assert json = JSON.parse(response.body)
    assert json['data'].length > 0
    this_region = json['data'].select {|entry| entry["name"] == "region_#{@random}"}
    assert_equal this_region.length, 1, json['data']
    assert_equal @region.id.to_s, this_region[0]['id'], this_region[0].inspect

    get :show, {"id" => @region.id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal @region.name, json['data']['name'], json['data'].inspect
  end

  test "test invalid id" do

    get :show, {"id" => "bogus"}
    assert_response :not_found

  end

  test "region selection flag true" do
    os = Rails.configuration.openshift
    Rails.configuration.stubs(:openshift).returns(os.merge(:allow_region_selection => true))
    get :index
    json = JSON.parse(response.body)
    assert_equal true, json['data'][0]['allow_selection']
  end

  test "region selection flag false" do
    os = Rails.configuration.openshift
    Rails.configuration.stubs(:openshift).returns(os.merge(:allow_region_selection => false))
    get :index
    json = JSON.parse(response.body)
    assert_equal false, json['data'][0]['allow_selection']
  end

end
