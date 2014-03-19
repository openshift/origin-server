ENV["TEST_NAME"] = "functional_teams_controller_test"
require 'test_helper'
class TeamsControllerTest < ActionController::TestCase

  def setup
    @controller = TeamsController.new

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
    CloudUser.any_instance.stubs(:max_teams).returns(3)
    stubber

  end

  def teardown
    begin
      @user.force_delete
    rescue
    end
  end

  test "team create show list update and destroy" do
    team_name = "team#{@random}"
    post :create, {"name" => team_name}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert json['data']['members'], response.body

    @controller = TeamsController.new
    get :show, {"id" => id}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert json['data']['members'], response.body

    @controller = TeamsController.new
    get :index , {}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert !json['data'][0]['members'], response.body

    @controller = TeamsController.new
    get :index , {:include => :members}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert json['data'][0]['members'], response.body

    @controller = TeamsController.new
    #new_name = "xteam#{@random}"
    #put :update, {"id" => id, "name" => new_name}
    #assert_response :success
    delete :destroy , {"id" => id}
    assert_response :ok
  end

  test "no team id or bad id" do
    get :show, {}
    assert_response :not_found
    get :show, {"id" => "bogus"}
    assert_response :not_found
    #put :update , {"name" => "ABCD1234XYX"}
    #assert_response :not_found
    delete :destroy , {}
    assert_response :not_found
  end

  test "duplicate or too many team" do
    team_name = "team#{@random}"
    post :create, {"name" => team_name}
    assert_response :created
    #same name
    post :create, {"name" => team_name}
    assert_response :unprocessable_entity
    
    CloudUser.any_instance.stubs(:max_teams).returns(1)
    post :create, {"name" => "other"}
    assert_response :forbidden
  end

  test "invalid inputs" do
    
    post :create, {"name" => ""}
    assert_response :unprocessable_entity
    
    post :create, {"name" => "a"*256}
    assert_response :unprocessable_entity
    
    #now try update
    #team_name = "team#{@random}"
    #post :create, {"name" => team_name}
    #assert_response :success
    #id = JSON.parse(response.body)["data"]["id"]
    #put :update , {"id" => id, "name" => "a"*256}
    #assert_response :unprocessable_entity
  end
  
  test "search" do
    Team.create(name: "myteam", owner_id: @user.id)
    Team.create(name: "mygroup", owner_id: @user.id)
    Team.create(name: "engineering-team", global: true, owner_id: @user.id)
    Team.create(name: "engineering-and-QE", global: true, owner_id: @user.id)
    
    # reset controller, since we're modifying data out-of-band, and want a new instance of the controller to look up the model again
    @controller = TeamsController.new
    
    get :index, {"search" => "team", "global" => true}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json["data"]
    assert_equal data.length, 1
    assert_equal data.first["name"] , "engineering-team"

    get :index, {"search" => "engineering", "global" => true}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json["data"]
    assert_equal data.length, 2
    assert data.select{|d| d["name"] == "engineering-team"}.count == 1
    assert data.select{|d| d["name"] == "engineering-and-QE"}.count == 1
    
    get :index, {"search" => "qe", "global" => true}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json["data"]
    assert_equal data.length, 1
    assert_equal data.first["name"] , "engineering-and-QE"
    
    get :index, {"search" => "my"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json["data"]
    assert_equal data.length, 2
    assert data.select{|d| d["name"] == "myteam"}.count == 1
    assert data.select{|d| d["name"] == "mygroup"}.count == 1
    
    get :index, {"search" => "team"}
    assert_response :success
    assert json = JSON.parse(response.body)
    assert data = json["data"]
    assert_equal data.length, 1
    assert_equal data.first["name"] , "myteam"
    
  end
  
  test "get teams in all versions" do
    team_name = "team#{@random}"
    post :create, {"name" => team_name}
    assert_response :created
    assert json = JSON.parse(response.body)
    assert id = json['data']['id']
    assert supported_api_versions = json['supported_api_versions']
    supported_api_versions.each do |version|
      @request.env['HTTP_ACCEPT'] = "application/json; version=#{version}"
      get :show, {"id" => id}
      assert_response :ok, "Getting team for version #{version} failed"
    end
  end
end
