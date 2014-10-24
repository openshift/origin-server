require File.expand_path('../../test_helper', __FILE__)

class TeamsControllerTest < ActionController::TestCase

  @@user = nil

  def setup
    with_user_with_allowed_teams
  end

  def with_particular_user
    if @@user
      set_user(@@user)
    else
      @@user = @user
    end
    with_team
  end

  def with_team
    @team = Team.first :params => {:include => "members"}, :as => @user
    unless @team
      @team = Team.new(get_post_form.merge(:as => @user))
      flunk @team.errors.inspect unless @team.save
    end
  end

  test "should return json for owned teams" do
    with_team

    Team.expects(:find).with() do |*args|
      args[0] == :all && args[1][:params] == {:owner => "@self"}
    end.returns([@team])

    @request.env['HTTP_ACCEPT'] = "application/json"
    get :index, {:owner => "@self"}

    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal [{'id' => @team.id, 'name' => @team.name}], json
  end

  test "should return json for global team search" do
    with_team

    Team.expects(:find).with() do |*args|
      args[0] == :all && args[1][:params] == {:search => "My Search", :global => true}
    end.returns([])

    @request.env['HTTP_ACCEPT'] = "application/json"
    get :index, {:search => "My Search", :global => "true"}

    assert_response :success
    assert json = JSON.parse(response.body)
    assert_equal [], json
  end

  test "should display team list" do
    with_team

    get :index

    assert teams = assigns(:teams)
    assert team = teams.first
    assert_equal @team, team
    assert team.members.present?
    assert assigns(:can_create) != nil
  end

  test "should show empty list" do
    Team.expects(:find).returns([])

    get :index

    assert teams = assigns(:teams)
    assert_equal [], teams
    assert assigns(:can_create) != nil
  end

  test "should show global team" do
    Team.expects(:find).returns([Team.new({:name => "global", :global => true, :id => "123"}, true)])

    get :index

    assert teams = assigns(:teams)
    assert_equal 1, teams.length
    assert assigns(:can_create) != nil
    assert_select "span:content(?)", /Shared team/
  end

  test "should display team creation form" do
    get :new

    assert team = assigns(:team)
    assert_response :success
    assert_template :new
  end

  test "show create button when max_teams is greater than number of owned teams" do
    owned = Team.new({:name => "owned", :id => "123"}, true)
    owned.expects(:owner?).at_least(0).returns(true)

    other = Team.new({:name => "other", :id => "234"}, true)
    other.expects(:owner?).at_least(0).returns(false)

    Console.config.capabilities_model_class.any_instance.expects(:max_teams).at_least(0).returns(5)
    Team.expects(:find).returns([owned]*3 + [other]*3)

    get :index

    assert_response :success
    assert_template :index
    assert teams = assigns(:teams)
    assert_equal 6, teams.count
    assert_equal true, assigns(:can_create)
    assert_select "a:content(?)", /Add/
  end

  test "hide create button when owned teams reaches max_teams" do
    owned = Team.new({:name => "owned", :id => "123"}, true)
    owned.expects(:owner?).at_least(0).returns(true)

    other = Team.new({:name => "other", :id => "234"}, true)
    other.expects(:owner?).at_least(0).returns(false)

    Console.config.capabilities_model_class.any_instance.expects(:max_teams).at_least(0).returns(3)
    Team.expects(:find).returns([owned]*3 + [other]*3)

    get :index

    assert_response :success
    assert_template :index
    assert teams = assigns(:teams)
    assert_equal 6, teams.count
    assert_equal false, assigns(:can_create)
    assert_select "a:content(?)", /Add Team/, :count => 0
  end

  test "hide create button when max_teams is 0" do
    Console.config.capabilities_model_class.any_instance.expects(:max_teams).at_least(0).returns(0)
    Team.expects(:find).returns([])

    get :index

    assert_response :success
    assert_template :index
    assert teams = assigns(:teams)
    assert_equal 0, teams.count
    assert_equal false, assigns(:can_create)
    assert_select "a:content(?)", /Add Team/, :count => 0
  end

  test "should create team" do
    post :create, {:team => get_post_form}

    assert team = assigns(:team)
    assert team.errors.empty?, team.errors.inspect
    assert_redirected_to team_path(team)
  end

  test "should create team and redirect" do
    post :create, {:team => get_post_form, :then => '/redirect?param1=value1&param2=value2', :team_param => 'param1'}

    assert team = assigns(:team)
    assert team.errors.empty?, team.errors.inspect
    assert_redirected_to "/redirect?param1=#{team.id}&param2=value2"
  end

  test "should assign errors on empty name" do
    post :create, {:team => get_post_form.merge(:name => '')}

    assert team = assigns(:team)
    assert !team.errors.empty?
    assert team.errors[:name].present?, team.errors.inspect
    assert !team.errors[:name].nil?
    assert team.errors[:name].include?("Name is required and cannot be blank"), team.errors[:name].inspect
    assert_template :new
  end

  test "should assign errors on long name" do
    post :create, {:team => get_post_form.merge(:name => 'aoeu'*2000)}

    assert team = assigns(:team)
    assert !team.errors.empty?
    assert team.errors[:name].present?, team.errors.inspect
    assert_equal 1, team.errors[:name].length, team.errors[:name].inspect
    assert_template :new
  end

  test "should assign errors on invalid name" do
    post :create, {:team => get_post_form.merge(:name => '@')}

    assert team = assigns(:team)
    assert !team.errors.empty?
    assert team.errors[:name].present?, team.errors.inspect
    assert_equal 1, team.errors[:name].length, team.errors[:name].inspect
    assert_template :new
  end

  test "should assign errors on duplicate name" do
    assert (team = Team.new(get_post_form.merge(:as => @user))).save, team.errors.inspect

    post :create, {:team => get_post_form.merge(:name => team.name)}

    assert team = assigns(:team)
    assert !team.errors.empty?
    assert team.errors[:name].present?, team.errors.inspect
    assert_equal 1, team.errors[:name].length, team.errors[:name].inspect
    assert_template :new
  end

  test "should show team page" do
    with_team

    Team.expects(:find).with() {|id, *args| id == @team.id }.returns(@team)

    get :show, {:id => @team.id}
    assert_template :show
    assert_response :success
  end

  test "should show delete page" do
    with_particular_user

    get :delete, {:id => @team.id}

    assert_response :success
    assert_template :delete
    assert team = assigns(:team)
  end

  test "should delete team successfully" do
    with_particular_user

    delete :destroy, {:id => @team.id}

    assert_redirected_to teams_path
    assert flash[:success] =~ /deleted/, "Expected a message about deleting the team"
    assert_raises(RestApi::ResourceNotFound) { Team.find(@team.id, :as => unique_user) }
  end

  test "should show team delete button for owner" do
    with_particular_user
    Team.any_instance.expects(:can_delete?).at_least(0).returns(true)
    Team.any_instance.expects(:can_leave?).at_least(0).returns(false)
    get :show, {:id => @team.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", /Delete this team/
    assert_select "a:content(?)", /Leave Team/, :count => 0
  end

  test "should show leave team button for explicit members" do
    with_particular_user
    Team.any_instance.expects(:can_delete?).at_least(0).returns(false)
    Team.any_instance.expects(:can_leave?).at_least(0).returns(true)
    get :show, {:id => @team.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", /Delete this team/, :count => 0
    assert_select "a:content(?)", /Leave Team/
  end

  test "should show team page and not show leave team button for domain admins that are not members" do
    with_particular_user
    Team.any_instance.expects(:owner?).at_least(0).returns(false)
    Team.any_instance.expects(:admin?).at_least(0).returns(true)
    Team.any_instance.expects(:me).at_least(0).returns(nil)
    get :show, {:id => @team.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", /Delete this team/, :count => 0
    assert_select "a:content(?)", /Leave Team/, :count => 0
  end

  test "should hide leave team button for global team members" do
    with_particular_user
    Team.any_instance.expects(:can_delete?).at_least(0).returns(false)
    Team.any_instance.expects(:can_leave?).at_least(0).returns(false)
    get :show, {:id => @team.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", /Delete this team/, :count => 0
    assert_select "a:content(?)", /Leave Team/, :count => 0
  end

  test "should render uneditable members successfully" do
    with_particular_user
    Team.any_instance.expects(:can_edit_membership?).at_least(0).returns(false)
    get :show, {:id => @team.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", "Add members...", :count => 0
    assert_select "a:content(?)", "Add a user...", :count => 0
    assert_select "a.edit-members:content(?)", "Edit members...", :count => 0
  end

  test "should render editable members with only owner successfully" do
    with_particular_user
    Team.any_instance.expects(:can_edit_membership?).at_least(0).returns(true)
    get :show, {:id => @team.id}
    assert_template :show
    assert_response :success
    assert_select "tr.type-user", :count => 0
    assert_select "a:content(?)", "Add members..."
    assert_select "a.edit-members:content(?)", "Edit members..."
  end

  test "should render editable members with explicit users successfully" do
    with_particular_user
    original_members = @team.members
    Team.any_instance.expects(:can_edit_membership?).at_least(0).returns(true)
    Team.any_instance.expects(:members).at_least(0).returns(
      [
        # Explicit member
        Team::Member.new(:type => 'user', :explicit_role => 'view', :role => 'view', :id => '345', :login => 'steve'),
      ] + original_members)
    get :show, {:id => @team.id}
    assert_template :show
    assert_response :success

    assert_select "tr.type-user", :count => 1
    assert_select "tr.type-user select[name='members[][role]'] option[selected='selected'][value='view']"

    assert_select "a:content(?)", "Add members...", :count => 0
    assert_select "a:content(?)", "Add a user..."
    assert_select "a.edit-members:content(?)", "Edit members..."
  end

  test "should hide team add function in members section" do
    with_particular_user
    Team.any_instance.expects(:can_edit_membership?).at_least(0).returns(true)

    get :show, {:id => @team.id}
    assert_template :show
    assert_response :success
    assert_select "a:content(?)", "Add a user..."
    assert_select "a:content(?)", "Add a team...", :count => 0
  end

  def get_post_form
    {:name => "t#{uuid[0..12]}"}
  end
end
