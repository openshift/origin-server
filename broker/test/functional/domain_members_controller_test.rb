ENV["TEST_NAME"] = "functional_domain_members_controller_test"
require 'test_helper'
class DomainMembersControllerTest < ActionController::TestCase

  def setup
    @controller = DomainMembersController.new

    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @owner = CloudUser.new(login: @login)
    @owner.private_ssl_certificates = true
    @owner.save
    Lock.create_lock(@owner.id)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    
    #create team for owner
    team_name = "team#{@random}"
    @team = Team.create(name: team_name, owner_id:@owner._id)
    #create another user to add to team as member
    team_member_name = "team_member#{@random}"
    @team_member = CloudUser.new(login: team_member_name)
    @team_member.save
    Lock.create_lock(@team_member.id)
    @team.add_members(@team_member)
    @team.save
    #create another user to add to domain as member directly
    member_login = "member#{@random}"
    @member = CloudUser.new(login: member_login)
    @member.save

    #create domain for user
    @namespace = "ns#{@random}"
    @domain = Domain.create!(namespace: @namespace, owner: @owner)

    stubber

  end

  def teardown
    begin
      @owner.force_delete
      @member.force_delete
      @team_member.force_delete
    rescue
      
    end
  end

  test "user member create show list update and destroy by login" do
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
    post :create, {"domain_id" => @domain.namespace, "login" => @member.login, "role" => "edit"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "edit"
    get :show, {"domain_id" => @domain.namespace, "id" => id}
    assert_response :success
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 2
    put :update, {"domain_id" => @domain.namespace, "id" => id, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data']["role"] , "view"
    delete :destroy , {"domain_id" => @domain.namespace, "id" => id}
    assert_response :success
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
  end
  
  test "user member create show list update and destroy by id" do
    post :create, {"domain_id" => @domain.namespace, "id" => @member._id, "role" => "edit"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "edit"
    
    get :show, {"domain_id" => @domain.namespace, "id" => id}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    
    put :update, {"domain_id" => @domain.namespace, "id" => id, "role" => "view"}
    assert_response :success
    
    assert json = JSON.parse(response.body)
    assert_equal json['data']["role"] , "view"
    
    delete :destroy , {"domain_id" => @domain.namespace, "id" => id}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
  end
  
  test "team member create show list update and destroy by id" do
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "edit", "type" => "team"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "edit"
    
    get :show, {"domain_id" => @domain.namespace, "id" => id, "type" => "team"}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    
    put :update, {"domain_id" => @domain.namespace, "id" => id, "role" => "view", "type" => "team"}
    assert_response :success
    
    delete :destroy , {"domain_id" => @domain.namespace, "id" => id, "type" => "team"}
    assert_response :success
  end
  
  test "mixed team and user member" do
    post :create, {"domain_id" => @domain.namespace, "members" => [{"id" => @team.id, "type" => "team", "role" => "view"} , {"login" => @member.login, "role" => "edit"}]}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json["data"]
    assert data.select{|d| d["login"] == @member.login and d["role"] == "edit"}.count == 1
    assert data.select{|d| d["type"] == "team" and d["role"] == "view"}.count == 1
    
    get :index , {"domain_id" => @domain.namespace}
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length, 4
    
    #should not be able to remove team member from domain
    post :create, {"domain_id" => @domain.namespace, "login" => @team_member.login, "role" => "none"}
    assert_response :unprocessable_entity
    
    get :index , {"domain_id" => @domain.namespace}
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length, 4
    
    post :create, {"domain_id" => @domain.namespace, "members" => [{"id" => @team.id, "type" => "team", "role" => "edit"} , {"login" => @member.login, "role" => "none"}]}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json["data"]
    assert_equal data.length, 3
    assert data.select{|d| d["login"] == @member.login and d["role"] == "edit"}.count == 0
    assert data.select{|d| d["type"] == "team" and d["role"] == "edit"}.count == 1
    
  end
  
  test "remove user via patch to role none" do
    post :create, {"domain_id" => @domain.namespace, "login" => @member.login, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "view"
    
    post :create, {"domain_id" => @domain.namespace, "login" => @member.login, "role" => "none"}
    assert_response :success
    
    post :create, {"domain_id" => @domain.namespace, "login" => @member.login, "role" => "none"}
    assert_response :unprocessable_entity
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1

    post :create, {"domain_id" => @domain.namespace, "id" => @member._id, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "view"
    
    post :create, {"domain_id" => @domain.namespace, "id" => @member._id, "role" => "none"}
    assert_response :success
    
    post :create, {"domain_id" => @domain.namespace, "id" => @member._id, "role" => "none"}
    assert_response :unprocessable_entity
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1

  end
  
  test "remove team via patch to role none" do
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "view", "type" => "team"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data']['role'] , "view"
    assert_equal json['data']['type'] , "team"
        
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "none", "type" => "team"}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1 
    
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "none", "type" => "team"}
    assert_response :unprocessable_entity
    
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "view", "type" => "team"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "view"
    
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "none", "type" => "team"}
    assert_response :success
    
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "none", "type" => "team"}
    assert_response :unprocessable_entity
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
  end
  
  test "remove user via put to role none" do
    post :create, {"domain_id" => @domain.namespace, "login" => @member.login, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    
    put :update, {"domain_id" => @domain.namespace, "id" => id, "role" => "none"}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
  end
  
  test "remove team via put to role none" do
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "view", "type" => "team"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    
    put :update, {"domain_id" => @domain.namespace, "id" => id, "role" => "none", "type" => "team"}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
  end
  
  test "delete user by id and login" do
    
    post :create, {"domain_id" => @domain.namespace, "id" => @member._id, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "view"
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 2
    
    delete :destroy, {"domain_id" => @domain.namespace, "id" => @member._id, "role" => "view"}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
    
    #by login
    post :create, {"domain_id" => @domain.namespace, "login" => @member.login, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "view"
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 2
    
    delete :destroy, {"domain_id" => @domain.namespace, "id" => id}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
  end
  
  test "remove team by id and name" do
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "view", "type" => "team"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "view"
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 3
    
    delete :destroy, {"domain_id" => @domain.namespace, "id" => @team.id, "type" => "team"}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
    
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "view", "type" => "team"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "view"
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 3
    
    delete :destroy, {"domain_id" => @domain.namespace, "id" => @team.id, "type" => "team"}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
  end

  test "no member id or bad id" do
    get :show, {"domain_id" => @domain.namespace}
    assert_response :not_found
    get :show, {"domain_id" => @domain.namespace, "id" => "bogus"}
    assert_response :not_found
    get :show, {"domain_id" => @domain.namespace, "id" => "bogus", "type" => "user"}
    assert_response :not_found
    get :show, {"domain_id" => @domain.namespace, "id" => "bogus", "type" => "team"}
    assert_response :not_found
    put :update , {"domain_id" => @domain.namespace, "role" => "view"}
    assert_response :not_found
  end
  
  test "no domain id or bad id" do
    get :show, {}
    assert_response :not_found
    get :show, {"domain_id" => "bogus"}
    assert_response :not_found
    put :update , {"role" => "admin"}
    assert_response :not_found
    delete :destroy , {}
    assert_response :not_found
  end

  test "invalid inputs" do
    
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "view"}
    assert_response :not_found
    
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "view", "type" => "user"}
    assert_response :not_found
    
    post :create, {"domain_id" => @domain.namespace, "id" => @member._id, "role" => "view", "type" => "team"}
    assert_response :not_found
    
    post :create, {"domain_id" => @domain.namespace, "login" => "bogus", "role" => "view"}
    assert_response :not_found
    
    post :create, {"domain_id" => @domain.namespace, "login" => "bogus", "role" => "view", "type" => "user"}
    assert_response :not_found
    
    post :create, {"domain_id" => @domain.namespace, "login" => @member.login, "role" => "view", "type" => "team"}
    assert_response :unprocessable_entity
    
    post :create, {"domain_id" => @domain.namespace, "login" => "", "role" => "view"}
    assert_response :unprocessable_entity
    
    post :create, {"domain_id" => @domain.namespace, "login" => @member.login, "role" => "bogus"}
    assert_response :unprocessable_entity
    
    post :create, {"domain_id" => @domain.namespace, "login" => @member.login, "role" => "view"}
    assert_response :success
    id = JSON.parse(response.body)["data"]["id"]
    put :update, {"domain_id" => @domain.namespace, "id" => id, "role" => "bogus"}
    assert_response :unprocessable_entity
    
    post :create, {"domain_id" => @domain.namespace, "id" => @member.login, "type" => "bad", "role" => "view"}
    assert_response :unprocessable_entity
    
    post :create, {"domain_id" => @domain.namespace, "id" => @member.login, "type" => "user", "role" => "bad"}
    assert_response :unprocessable_entity
  end
  
  test "adding updating and removing a team not owned by user" do
    
    #create a team for other member
    @otherteam = Team.create(name: "myteam", owner_id:@member._id)
    #add domain owner to team so the team would be visible
    @otherteam.add_members(@owner)
    @otherteam.save
    post :create, {"domain_id" => @domain.namespace, "id" => @otherteam.id, "type" => "team", "role" => "view"}
    assert_response :not_found
    
    #now add team
    #@domain.add_members(@otherteam)
    #@domain.save
    #@domain.run_jobs
    
    #get :show, {"domain_id" => @domain.namespace, "id" => @otherteam.id, "type" => "team"}
    #assert_response :success
    
    # make sure the user can update it and remove it
    #post :create, {"domain_id" => @domain.namespace, "id" => @otherteam.id, "type" => "team", "role" => "edit"}
    #assert_response :success
    
    #post :create, {"domain_id" => @domain.namespace, "id" => @otherteam.id, "type" => "team", "role" => "none"}
    #assert_response :success
    
    #get :index , {"domain_id" => @domain.namespace}
    #assert_response :success
    #assert json = JSON.parse(response.body)
    #assert_equal json['data'].length , 1
  end

  test "get member in all versions" do
    post :create, {"domain_id" => @domain.namespace, "login" => @member.login, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"domain_id" => @domain.namespace, "id" => id}
      assert_response :ok, "Getting domain for version #{version} failed"
    end
  end
end
