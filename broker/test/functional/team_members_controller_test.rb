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
    Lock.create_lock(@user.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    team_name = "team#{@random}"
    @team = Team.create(name: team_name, owner_id:@user._id)
    member_name = "member1-#{@random}"
    @member1 = CloudUser.new(login: member_name)
    @member1.save
    Lock.create_lock(@member1.id)
    
    member_name = "member2-#{@random}"
    @member2 = CloudUser.new(login: member_name)
    @member2.save
    Lock.create_lock(@member2.id)

    stubber

  end

  def teardown
    begin
      @user.force_delete
      @member1.force_delete
      @member2.force_delete
    rescue Exception => ex
      puts ex
    end
  end

  test "member create show list update and destroy by login" do
    post :create, {"team_id" => @team.id, "login" => @member1.login, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json['data'] 
    assert id = data['id']
    assert data['role'] == "view"
    assert data['login'] == @member1.login
    get :show, {"team_id" => @team.id, "id" => id}
    assert_response :success
    get :index , {"team_id" => @team.id}
    assert_response :success
    put :update, {"team_id" => @team.id, "id" => id, "role" => "view"}
    assert_response :success
    delete :destroy , {"team_id" => @team.id, "id" => id}
    assert_response :success
  end
  
  test "member create show list update and destroy by id" do
    post :create, {"team_id" => @team.id, "id" => @member1._id, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json['data'] 
    assert id = data['id']
    assert data['role'] == "view"
    assert data['login'] == @member1.login
    get :show, {"team_id" => @team.id, "id" => id}
    assert_response :success
    get :index , {"team_id" => @team.id}
    assert_response :success
    put :update, {"team_id" => @team.id, "id" => id, "role" => "view"}
    assert_response :success
    delete :destroy , {"team_id" => @team.id, "id" => id}
    assert_response :success
  end
  
  test "member create via member or members" do
    post :create, {"team_id" => @team.id, "member" => {"id" => @member1._id, "role" => "view"}}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json['data'] 
    assert id = data['id']
    assert data['role'] == "view"
    assert data['login'] == @member1.login
    
    get :index , {"team_id" => @team.id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length, 2
    
    post :create, {"team_id" => @team.id, "member" => { "id" => @member1._id, "role" => "none"}}
    assert_response :success
    
    get :index , {"team_id" => @team.id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length, 1
    
    post :create, {"team_id" => @team.id, "members" => [{ "id" => @member1._id, "role" => "view"},{"id" => @member2._id, "role" => "view"}]}
    assert_response :success

    get :index , {"team_id" => @team.id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length, 3
    
    post :create, {"team_id" => @team.id, "members" => [{ "id" => @member1._id, "role" => "none"},{"id" => @member2._id, "role" => "view"}]}
    assert_response :success
    
    get :index , {"team_id" => @team.id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length, 2
    
    post :create, {"team_id" => @team.id, "member" => { "id" => @member2._id, "role" => "none"}}
    assert_response :success
    
    get :index , {"team_id" => @team.id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length, 1
    
  end
  
  test "remove member via patch to role none" do
    post :create, {"team_id" => @team.id, "login" => @member1.login, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json['data'] 
    assert id = data['id']
    assert data['role'] == "view"
    assert data['login'] == @member1.login
    
    get :index , {"team_id" => @team.id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert json['data'].length == 2
    
    post :create, {"team_id" => @team.id, "login" => @member1.login, "role" => "none"}
    assert_response :success
    get :index , {"team_id" => @team.id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert json['data'].length == 1
  end
  
  test "remove member via put to role none" do
    post :create, {"team_id" => @team.id, "login" => @member1.login, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json['data'] 
    assert id = data['id']
    
    post :update, {"team_id" => @team.id, "id" => id, "role" => "none"}
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
    put :update , {"team_id" => @team.id, "role" => "view"}
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
    post :create, {"team_id" => @team.id, "login" => "bogus", "role" => "view"}
    assert_response :not_found
    
    post :create, {"team_id" => @team.id, "login" => "", "role" => "view"}
    assert_response :unprocessable_entity
    
    post :create, {"team_id" => @team.id, "login" => @member1.login}
    assert_response :unprocessable_entity

    post :create, {"team_id" => @team.id, "login" => @member1.login, "role" => ""}
    assert_response :unprocessable_entity

    post :create, {"team_id" => @team.id, "login" => @member1.login, "role" => "bogus"}
    assert_response :unprocessable_entity
    
    post :create, {"team_id" => @team.id, "id" => @member1.id, "role" => "view", "type" => "team"}
    assert_response :unprocessable_entity
    
    post :create, {"team_id" => @team.id, "login" => @member1.login, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json['data'] 
    assert id = data['id']
    put :update, {"team_id" => @team.id, "id" => id}
    assert_response :unprocessable_entity
    put :update, {"team_id" => @team.id, "id" => id, "role" => "bogus"}
    assert_response :unprocessable_entity
    put :update, {"team_id" => @team.id, "id" => id, "role" => "admin"}
    assert_response :unprocessable_entity
  end

  test "get member in all versions" do
    post :create, {"team_id" => @team.id, "login" => @member1.login, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json['data']
    assert id = data['id']
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"team_id" => @team.id, "id" => id}
      assert_response :ok, "Getting team for version #{version} failed"
    end
  end
end
