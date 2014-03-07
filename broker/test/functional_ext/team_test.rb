ENV["TEST_NAME"] = "functional_ext_team_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha/setup'

class TeamTest < ActionDispatch::IntegrationTest

  TEAMS_URL = "/broker/rest/teams"
  TEAM_URL = "/broker/rest/team"
  TEAM_MEMBERS_URL = "/broker/rest/team/%s/members"
  TEAM_MEMBER_URL = "/broker/rest/team/%s/member"


  def setup
    @random = rand(1000000000)
    @login = "user#{@random}"
    @password = "password"
    @headers = {}
    @headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("#{@login}:#{@password}")
    @headers["HTTP_ACCEPT"] = "application/json"
    @headers['REMOTE_USER'] = @login
    register_user(@login, @password)

    https!
  end

  def test_team_show
    name = "team#{@random}"

    # query team list when team not yet created
    request_via_redirect(:get, TEAMS_URL, {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 0)

    # create team
    request_via_redirect(:post, TEAMS_URL, {:name => name, :nolinks => true}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], name)
    id = body["data"]["id"]

    # test fetching team by id
    request_via_redirect(:get, TEAM_URL + "/#{id}", {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"]["name"], name)

    # test getting team list
    request_via_redirect(:get, TEAMS_URL, {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert_equal(body["data"].length, 1)
    assert_equal(body["data"][0]["name"], name)
  end

  def test_team_create_validation
    # team name not specified
    request_via_redirect(:post, TEAMS_URL, {:nolinks => true}, @headers)
    assert_response :unprocessable_entity

    # team name too short
    request_via_redirect(:post, TEAMS_URL, {:name => "", :nolinks => true}, @headers)
    assert_response :unprocessable_entity

    # team name too long
    request_via_redirect(:post, TEAMS_URL, {:name => "a"*256, :nolinks => true}, @headers)
    assert_response :unprocessable_entity

  end

  def test_team_create
    name = "team#{@random}"
    new_name = "team#{@random}x"

    # team should get created
    request_via_redirect(:post, TEAMS_URL, {:name => name, :nolinks => true}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    id = body["data"]["id"]

    CloudUser.any_instance.stubs(:max_teams).returns(2)

    # team creation should fail because name is already used
    request_via_redirect(:post, TEAMS_URL, {:name => name, :nolinks => true}, @headers)
    assert_response :unprocessable_entity


    CloudUser.any_instance.stubs(:max_teams).returns(1)

    # team creation should fail because user already has a team
    request_via_redirect(:post, TEAMS_URL, {:name => name, :nolinks => true}, @headers)
    assert_response :conflict

  end

  def test_team_update_validation
    name = "team#{@random}"
    new_name = "team#{@random}x"

    # create the initial team for the user
    request_via_redirect(:post, TEAMS_URL, {:name => name, :nolinks => true}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    id = body["data"]["id"]

    # new team name not specified
    request_via_redirect(:put, TEAM_URL + "/#{id}", {}, @headers)
    assert_response :unprocessable_entity
    body = JSON.parse(@response.body)

    # new team name too short
    request_via_redirect(:put, TEAM_URL + "/#{id}", {:name => ""}, @headers)
    assert_response :unprocessable_entity

    # new team name too long
    request_via_redirect(:put, TEAM_URL + "/#{id}", {:name => "a"*256}, @headers)
    assert_response :unprocessable_entity


    # try to update another user's team
    @new_headers = {}
    @new_headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("new#{@login}:password")
    @new_headers["HTTP_ACCEPT"] = "application/json"
    @new_headers['REMOTE_USER'] = "new#{@login}"
    register_user("new#{@login}","password")
    request_via_redirect(:put, TEAM_URL + "/#{id}", {:name => new_ns}, @new_headers)
    assert_response :not_found

  end

  def test_team_delete
    name = "team#{@random}"
    new_ns = "newns#{@random}"

    # create the team for the user
    request_via_redirect(:post, TEAMS_URL, {:name => name, :nolinks => true}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    id = body["data"]["id"]

    # try to delete another user's team
    @new_headers = {}
    @new_headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("new#{@login}:password")
    @new_headers["HTTP_ACCEPT"] = "application/json"
    @new_headers['REMOTE_USER'] = "new#{@login}"
    register_user("new#{@login}","password")
    request_via_redirect(:delete, TEAM_URL + "/#{id}", {}, @new_headers)
    assert_response :not_found

    # delete the team
    request_via_redirect(:delete, TEAM_URL + "/#{id}", {}, @headers)
    assert_response :ok

    # query team after deletion
    request_via_redirect(:get, TEAM_URL + "/#{id}", {}, @headers)
    assert_response :not_found

    # recreate the team with the same name - checking name availability
    request_via_redirect(:post, TEAMS_URL, {:name => name, :nolinks => true}, @headers)
    assert_response :created
  end
  
  def test_team_membership
    name = "team#{@random}"

    # create the team for the user
    request_via_redirect(:post, TEAMS_URL, {:name => name, :nolinks => true}, @headers)
    assert_response :created
    body = JSON.parse(@response.body)
    id = body["data"]["id"]
    
    register_user("member1", "password")
    register_user("member2", "password")
    register_user("member3", "password")
    
    request_via_redirect(:post, TEAM_MEMBERS_URL % [id], {:login => "member1", :nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    m_id = body["data"]["id"]
    
    request_via_redirect(:get, TEAM_MEMBER_URL % [id, m_id], {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert body["data"]["name"] == "member1"
    
    request_via_redirect(:get, TEAM_MEMBERS_URL % [id], {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert body["data"].length == 2
    
    request_via_redirect(:put, TEAM_MEMBER_URL % [id, m_id], {:role => "none", :nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert body["data"]["name"] == "member1"
    
    request_via_redirect(:get, TEAM_MEMBERS_URL % [id], {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert body["data"].length == 1
    
    request_via_redirect(:post, TEAM_MEMBERS_URL % [id], {:login => "member1, member2, member3", :nolinks => true}, @headers)
    assert_response :ok

    request_via_redirect(:get, TEAM_MEMBERS_URL % [id], {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert body["data"].length == 4
    
    request_via_redirect(:post, TEAM_MEMBERS_URL % [id], {:login => "member3", :role => "none", :nolinks => true}, @headers)
    assert_response :ok
    
    request_via_redirect(:get, TEAM_MEMBERS_URL % [id], {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert body["data"].length == 3
    
    # owner should not be able to leave
    request_via_redirect(:delete, TEAM_MEMBERS_URL % [id] + "/self", {:nolinks => true}, @headers)
    assert_response :unprocessable_entity
    
    # others should be able to leave
    @new_headers = {}
    @new_headers["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64("member2:password")
    @new_headers["HTTP_ACCEPT"] = "application/json"
    @new_headers['REMOTE_USER'] = "member2"
    request_via_redirect(:delete, TEAM_MEMBERS_URL % [id] + "/self", {:nolinks => true}, @new_headers)
    assert_response :ok
    
    request_via_redirect(:get, TEAM_MEMBERS_URL % [id], {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert body["data"].length == 2
    
    #delete all members
    request_via_redirect(:delete, TEAM_MEMBERS_URL % [id], {:nolinks => true}, @headers)
    assert_response :ok
    # owner should still be there
    request_via_redirect(:get, TEAM_MEMBERS_URL % [id], {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert body["data"].length == 1
    
    #delete individual member
    request_via_redirect(:post, TEAM_MEMBERS_URL % [id], {:login => "member1", :nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    m_id = body["data"]["id"]
    
    request_via_redirect(:delete, TEAM_MEMBER_URL % [id, m_id], {:nolinks => true}, @headers)
    assert_response :ok
    
    #delete owner
    request_via_redirect(:get, TEAM_MEMBERS_URL % [id], {:nolinks => true}, @headers)
    assert_response :ok
    body = JSON.parse(@response.body)
    assert body["data"].length == 1
    owner_id = body["data"].first["id"]
    request_via_redirect(:delete, TEAM_MEMBER_URL % [id, owner_id], {:nolinks => true}, @headers)
    assert_response :unprocessable_entity
  end

end
