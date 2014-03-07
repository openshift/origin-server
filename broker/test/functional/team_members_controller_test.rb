ENV["TEST_NAME"] = "functional_team_members_controller_test"
require 'test_helper'
class TeamMembersControllerTest < ActionController::TestCase

  def setup
    @controller = TeamMembersController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @user = CloudUser.new(login: @login)
    @user.private_ssl_certificates = true
    @user.save
    Lock.create_lock(@user)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    team_name = "team#{@random}"
    @team = Team.create(name: team_name, owner_id:@user._id)
    @member_name = "member#{@random}"
    member = CloudUser.new(login: @member_name)
    member.save
    Lock.create_lock(member)

    stubber

  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "member create show list update and destroy" do
    post :create, {"team_id" => @team.id, "login" => @member_name}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert json['data']['role'] == "view"
    get :show, {"team_id" => @team.id, "id" => id}
    assert_response :success
    get :index , {"team_id" => @team.id}
    assert_response :success
    put :update, {"team_id" => @team.id, "id" => id, "role" => :view}
    assert_response :success
    delete :destroy , {"team_id" => @team.id, "id" => id}
    assert_response :success
  end
  
  test "remove member via patch to role none" do
    post :create, {"team_id" => @team.id, "login" => @member_name}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert json['data']['role'] == "view"
    
    post :create, {"team_id" => @team.id, "login" => @member_name, "role" => :none}
    assert_response :success
    get :index , {"team_id" => @team.id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert json['data'].length == 1
  end
  
  test "remove member via put to role none" do
    post :create, {"team_id" => @team.id, "login" => @member_name}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    
    post :update, {"team_id" => @team.id, "id" => id, "role" => :none}
    assert_response :success
    get :index , {"team_id" => @team.id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert json['data'].length == 1
  end

  test "no member id or bad id" do
    get :show, {"team_id" => @team.id}
    assert_response :not_found
    get :show, {"team_id" => @team.id, "id" => "bogus"}
    assert_response :not_found
    put :update , {"team_id" => @team.id, "role" => :view}
    assert_response :not_found
  end
  
  test "no team id or bad id" do
    get :show, {}
    assert_response :not_found
    get :show, {"team_id" => "bogus"}
    assert_response :not_found
    put :update , {"role" => :admin}
    assert_response :not_found
    delete :destroy , {}
    assert_response :not_found
  end

  test "invalid inputs" do
    post :create, {"team_id" => @team.id, "login" => "bogus"}
    assert_response :not_found
    
    post :create, {"team_id" => @team.id, "login" => ""}
    assert_response :unprocessable_entity
    
    post :create, {"team_id" => @team.id, "login" => @member_name, "role" => :bogus}
    assert_response :unprocessable_entity
    
    post :create, {"team_id" => @team.id, "login" => @member_name}
    assert_response :success
    id = JSON.parse(response.body)["data"]["id"]
    put :update, {"team_id" => @team.id, "id" => id, "role" => :bogus}
    assert_response :unprocessable_entity
  end

  test "get member in all versions" do
    post :create, {"team_id" => @team.id, "login" => @member_name}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"team_id" => @team.id, "id" => id}
      assert_response :ok, "Getting team for version #{version} failed"
    end
  end
end
