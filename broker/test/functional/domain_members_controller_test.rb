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
    Lock.create_lock(@owner)
    register_user(@login, @password)

    @request.env['HTTP_AUTHORIZATION'] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @request.env['REMOTE_USER'] = @login
    @request.env['HTTP_ACCEPT'] = "application/json"
    
    #create team for owner
    team_name = "team#{@random}"
    @team = Team.create(name: team_name, owner_id:@owner._id)
    #create another user to add to team as member
    @team_member_name = "team_member#{@random}"
    @team_member = CloudUser.new(login: @team_member_name)
    @team_member.save
    Lock.create_lock(@team_member)
    @team.add_members(@team_member)
    @team.save
    #create another user to add to domain as member directly
    @member_name = "member#{@random}"
    @member = CloudUser.new(login: @member_name)
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
    post :create, {"domain_id" => @domain.namespace, "login" => @member_name, "role" => "edit"}
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
  
  test "team member create show list update and destroy by name" do
    post :create, {"domain_id" => @domain.namespace, "name" => @team.name, "role" => "edit", "type" => "team"}
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
    
    delete :destroy , {"domain_id" => @domain.namespace, "id" => id}
    assert_response :success
  end
  
  test "team member create show list update and destroy by id" do
    post :create, {"domain_id" => @domain.namespace, "id" => @team.id, "role" => "edit", "type" => "team"}
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
    
    delete :destroy , {"domain_id" => @domain.namespace, "id" => id}
    assert_response :success
  end
  
  test "mixed team and user member create show list update and destroy" do
    post :create, {"domain_id" => @domain.namespace, "members" => [{"name" => @team.name, "type" => "team", "role" => "view"} , {"login" => @member_name, "role" => "edit"}]}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "edit"
    
    get :show, {"domain_id" => @domain.namespace, "id" => id}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 2
    
    put :update, {"domain_id" => @domain.namespace, "id" => id, "role" => "view"}
    assert_response :success
    
    delete :destroy , {"domain_id" => @domain.namespace, "id" => id}
    assert_response :success
  end
  
  test "remove member via patch to role none" do
    post :create, {"domain_id" => @domain.namespace, "login" => @member_name, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert_equal json['data']['role'] , "view"
    
    post :create, {"domain_id" => @domain.namespace, "login" => @member_name, "role" => "none"}
    assert_response :success
    
    get :index , {"domain_id" => @domain.namespace}
    assert_response :success
    
    assert json = JSON.parse(response.body)
    assert_equal json['data'].length , 1
  end
  
  test "remove member via put to role none" do
    post :create, {"domain_id" => @domain.namespace, "login" => @member_name, "role" => "view"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    
    post :update, {"domain_id" => @domain.namespace, "id" => id, "role" => "none"}
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
    post :create, {"domain_id" => @domain.namespace, "login" => "bogus", "role" => "view"}
    assert_response :not_found
    
    post :create, {"domain_id" => @domain.namespace, "login" => "", "role" => "view"}
    assert_response :unprocessable_entity
    
    post :create, {"domain_id" => @domain.namespace, "login" => @member_name, "role" => "bogus"}
    assert_response :unprocessable_entity
    
    post :create, {"domain_id" => @domain.namespace, "login" => @member_name, "role" => "view"}
    assert_response :success
    id = JSON.parse(response.body)["data"]["id"]
    put :update, {"domain_id" => @domain.namespace, "id" => id, "role" => "bogus"}
    assert_response :unprocessable_entity
  end

  test "get member in all versions" do
    post :create, {"domain_id" => @domain.namespace, "login" => @member_name, "role" => "view"}
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
