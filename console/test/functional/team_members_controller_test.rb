require File.expand_path('../../test_helper', __FILE__)

class TeamMembersControllerTest < ActionController::TestCase

  def setup
    with_user_with_allowed_teams
    with_team
  end

  def with_team
    @team = Team.first :params => {:include => "members"}, :as => @user
    unless @team
      @team = Team.new(get_post_form.merge(:as => @user))
      flunk @team.errors.inspect unless @team.save
    end
  end

  def test_get_index_redirects
    get :index, {:team_id => @team}
    assert_redirected_to team_path(@team)
  end

  def test_update_without_params
    Team.any_instance.expects(:update_members).never
    put :update, {:team_id => @team}
    assert_redirected_to team_path(@team)    
  end

  def test_update_single_member_error
    put :update, {
      :team_id => @team,
      :members => {:type => 'user', :role => 'view', :login => 'x', :adding => 'true'}
    }
    assert_response :success
    assert_template 'teams/show'
    assert_equal "The team members could not be updated.", flash[:error]
    assert new_members = assigns[:new_members]
    assert_equal 1, new_members.count
    assert new_members[0].errors[:login].to_s =~ /x/

    assert_select '.members.editing'
    assert_select "input[name='members[][login]']", :count => 2
    assert_select "input[name='members[][role]'][type='hidden']", :count => 2
    assert_select "tr.template input[name='members[][login]']", :count => 1
    assert_select "tr.template input[name='members[][role]'][type='hidden']", :count => 1
  end

  def test_update_multi_member_error
    put :update, {
      :team_id => @team,
      :members => [
        {:type => 'user', :role => 'view', :login => 'x', :adding => 'true'},
        {:type => 'user', :role => 'view', :login => 'y', :adding => 'true'}
      ]
    }
    assert_response :success
    assert_template 'teams/show'
    assert_equal "The team members could not be updated.", flash[:error]
    assert new_members = assigns[:new_members]
    assert_equal 2, new_members.count
    assert new_members[0].errors[:login].to_s =~ /x/
    assert new_members[1].errors[:login].to_s =~ /y/

    assert_select '.members.editing'

    assert_select "input[name='members[][login]']", :count => 3
    assert_select "tr.template input[name='members[][login]']", :count => 1
  end

  def test_update_single_member_success
    Team.any_instance.expects(:update_members).returns(true)
    put :update, {
      :team_id => @team,
      :members => {:type => 'user', :role => 'view', :login => 'x'}
    }
    assert_redirected_to team_path(@team) 
    assert flash[:success]
  end

  def test_update_multi_member_success
    Team.any_instance.expects(:update_members).returns(true)
    put :update, {
      :team_id => @team,
      :members => [
        {:type => 'user', :role => 'view', :login => 'x'},
        {:type => 'user', :role => 'none', :login => 'y'}
      ]
    }
    assert_redirected_to team_path(@team) 
    assert flash[:success]
  end

  def test_leave
    Team.any_instance.expects(:leave).never
    get :leave, {:team_id => @team}
    assert_response :success
    assert_template 'members/leave'

    Team.any_instance.expects(:leave).once.returns(false)
    post :leave, {:team_id => @team}
    assert_redirected_to team_path(@team)
    assert flash[:error]

    Team.any_instance.expects(:leave).once.returns(true)
    post :leave, {:team_id => @team}
    assert_redirected_to teams_path
    assert flash[:success]
  end

  protected
    def get_post_form
      {:name => "t#{uuid[0..12]}"}
    end

end
