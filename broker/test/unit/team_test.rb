require_relative '../test_helper'

class TeamTest < ActiveSupport::TestCase

  setup do 
    @to_delete = {}
  end

  teardown do
    [:teams,:domains,:users].each do |type|
      Array(@to_delete[type]).each do |obj|
        obj.reload.delete rescue nil
      end
    end
  end

  def explicit_role_for(resource, member_or_id)
    id = member_or_id.respond_to?(:_id) ? member_or_id._id : member_or_id
    type = (member_or_id.class.member_type if member_or_id.class.respond_to?(:member_type)) || CloudUser.member_type
    resource.members.each do |m|
      return m.explicit_role if m._id == id and m.type == type
    end
    nil
  end

  def with_membership(&block)
    yield
  end

  def without_membership(&block)
    # do nothing
  end

  def with_config(sym, value, base=:openshift, &block)
    c = Rails.configuration.send(base)
    @old =  c[sym]
    c[sym] = value
    yield
  ensure
    c[sym] = @old
  end

  def test_non_member_team_destroy
    Team.where(:name => 'non-member-team-destroy').delete
    assert t = Team_create(:name => 'non-member-team-destroy')
    assert t.destroy
  end

  # Explicit view -> team edit -> explicit admin
  def test_raise_explicit_role_of_team_member
    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser_create(:login => 'team-member-1')

    Team.where(:name => 'member-team-1').delete
    assert t1 = Team_create(:name => 'member-team-1')
    t1.add_members u1, :view
    t1.save
    t1.run_jobs

    d.add_members u1, :view
    d.save
    d.run_jobs
    assert_equal :view, d.reload.role_for(u1)

    d.add_members t1, :edit
    d.save
    d.run_jobs
    assert_equal :edit, d.reload.role_for(u1)
    assert_equal :view, explicit_role_for(d, u1)

    d.add_members u1, :admin
    d.save
    d.run_jobs
    assert_equal :admin, d.reload.role_for(u1)
  end

  # Explicit admin -> team edit -> explicit view
  def test_lower_explicit_role_of_team_member
    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser_create(:login => 'team-member-1')

    Team.where(:name => 'member-team-1').delete
    assert t1 = Team_create(:name => 'member-team-1')
    t1.add_members u1, :view
    t1.save
    t1.run_jobs

    d.add_members u1, :admin
    d.save
    d.run_jobs
    assert_equal :admin, d.reload.role_for(u1)

    d.add_members t1, :edit
    d.save
    d.run_jobs
    assert_equal :admin, d.reload.role_for(u1)

    d.add_members u1, :view
    d.save
    d.run_jobs
    assert_equal :edit, d.reload.role_for(u1)
    assert_equal :view, explicit_role_for(d, u1)
  end

  # Explicit view -> team edit -> remove explicit
  def test_remove_lower_explicit_role_of_team_member
    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser_create(:login => 'team-member-1')

    Team.where(:name => 'member-team-1').delete
    assert t1 = Team_create(:name => 'member-team-1')
    t1.add_members u1, :view
    t1.save
    t1.run_jobs

    d.add_members u1, :view
    d.save
    d.run_jobs
    assert_equal :view, d.reload.role_for(u1)

    d.add_members t1, :edit
    d.save
    d.run_jobs
    assert_equal :edit, d.reload.role_for(u1)

    d.remove_members u1
    d.save
    d.run_jobs
    assert_equal :edit, d.reload.role_for(u1)
    assert_equal nil, explicit_role_for(d, u1)
  end

  # Explicit admin -> team edit -> remove explicit
  def test_remove_higher_explicit_role_of_team_member
    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser_create(:login => 'team-member-1')

    Team.where(:name => 'member-team-1').delete
    assert t1 = Team_create(:name => 'member-team-1')
    t1.add_members u1, :view
    t1.save
    t1.run_jobs

    d.add_members u1, :admin
    d.save
    d.run_jobs
    assert_equal :admin, d.reload.role_for(u1)

    d.add_members t1, :edit
    d.save
    d.run_jobs
    assert_equal :admin, d.reload.role_for(u1)

    d.remove_members u1
    d.save
    d.run_jobs
    assert_equal :edit, d.reload.role_for(u1)
    assert_equal nil, explicit_role_for(d, u1)
  end

  def test_update_explicit_role_of_team_member
    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser_create(:login => 'team-member-1')

    Team.where(:name => 'member-team-1').delete
    assert t1 = Team_create(:name => 'member-team-1')
    t1.add_members u1, :view
    t1.save
    t1.run_jobs

    d.add_members t1, :edit
    d.save
    d.run_jobs
    d.reload

    assert_equal :edit, d.role_for(t1)
    assert_equal :edit, d.role_for(u1)

    d.add_members u1, :admin
    d.save
    d.run_jobs
    d.reload

    assert_equal :edit,  d.role_for(t1)
    assert_equal :admin, d.role_for(u1)

    d.add_members u1, :edit
    d.save
    d.run_jobs
    d.reload

    assert_equal :edit, d.role_for(t1)
    assert_equal :edit, d.role_for(u1)

    d.remove_members u1
    d.save
    d.run_jobs
    d.reload

    assert_equal :edit, d.role_for(t1)
    assert_equal :edit, d.role_for(u1)

    d.remove_members t1
    d.save
    d.run_jobs
    d.reload

    assert_equal nil, d.role_for(t1)
    assert_equal nil, d.role_for(u1)
  end


  def test_remove_single_team
    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser_create(:login => 'team-member-1')

    CloudUser.where(:login => 'explicit-member-1').delete
    assert u2 = CloudUser_create(:login => 'explicit-member-1')

    Team.where(:name => 'member-team-1').delete
    assert t1 = Team_create(:name => 'member-team-1')
    t1.add_members u1, :view
    t1.save
    t1.run_jobs

    Team.where(:name => 'member-team-2').delete
    assert t2 = Team_create(:name => 'member-team-2')
    t2.add_members u1, :view
    t2.save
    t2.run_jobs

    d.add_members t1, :edit
    d.add_members t2, :view
    d.add_members u2, :view
    d.save
    d.run_jobs

    assert_equal :edit, d.role_for(t1)
    assert_equal :view, d.role_for(t2)
    assert_equal :edit, d.role_for(u1)
    assert_equal :view, d.role_for(u2)

    d.remove_members t1
    d.save
    d.run_jobs

    assert_equal nil,   d.role_for(t1)
    assert_equal :view, d.role_for(t2)
    assert_equal :view, d.role_for(u1)
    assert_equal :view, d.role_for(u2)

    d.remove_members t2
    d.save
    d.run_jobs

    assert_equal nil,   d.role_for(t1)
    assert_equal nil,   d.role_for(t2)
    assert_equal nil,   d.role_for(u1)
    assert_equal :view, d.role_for(u2)
  end

  def test_add_and_remove_in_single_operation
    # A remove op shouldn't fail because the team member has already been removed
    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser_create(:login => 'team-member-1')

    Team.where(:name => 'member-team').delete
    assert t = Team_create(:name => 'member-team')

    t.add_members u1, :view
    t.remove_members u1
    t.save
    t.run_jobs

    d.add_members t, :view
    d.remove_members t
    d.save
    d.run_jobs

    # Make sure the user's not a member of the domain or team
    assert_equal nil, t.role_for(u1)
    assert_equal nil, d.role_for(u1)

    # Make sure the team's not a member of the domain
    assert_equal nil, d.role_for(t)
  end

  def test_remove_twice
    # A remove op shouldn't fail because the team member has already been removed
    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser_create(:login => 'team-member-1')

    Team.where(:name => 'member-team').delete
    assert t = Team_create(:name => 'member-team')

    t.add_members u1, :view
    t.save
    t.run_jobs

    d.add_members t, :view
    d.save
    d.run_jobs

    # Make sure the user's a member of the domain
    assert_equal :view, d.role_for(u1)

    # Mess with the domain membership to simulate the user already being removed
    d.members = d.members.select(&:team?)
    d.save

    # Tolerate a double-remove before saving
    t.remove_members u1
    t.remove_members u1
    t.save
    t.run_jobs

    # Tolerate a remove of a non-existent member
    t.remove_members u1
    t.save
    t.run_jobs    
  end

  def test_adding_to_elevated_team_elevates
      Domain.where(:namespace => 'test').delete
      assert d = Domain_create(:namespace => 'test')

      CloudUser.where(:login => 'team-member-1').delete
      assert u1 = CloudUser_create(:login => 'team-member-1')

      # Set up a team with no members
      Team.where(:name => 'member-team-propagate').delete
      assert t = Team_create(:name => 'member-team-propagate')

      assert d.add_members u1, :view
      assert d.add_members t, :edit
      assert d.save
      assert d.run_jobs
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)
      assert_equal :edit, d.role_for(t)
      assert_equal :edit, explicit_role_for(d, t)

      assert t.add_members u1, :view
      assert t.save
      assert t.run_jobs
      assert d.reload
      assert_equal :edit, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)

      assert t.add_members u1, :admin
      assert t.save
      assert t.run_jobs
      assert d.reload
      assert_equal :edit, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)

      assert t.remove_members u1
      assert t.save
      assert t.run_jobs
      assert d.reload
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)
  end

  def test_adding_to_unprivileged_team_leaves_elevated
      Domain.where(:namespace => 'test').delete
      assert d = Domain_create(:namespace => 'test')

      CloudUser.where(:login => 'team-member-1').delete
      assert u1 = CloudUser_create(:login => 'team-member-1')

      # Set up a team with no members
      Team.where(:name => 'member-team-propagate').delete
      assert t = Team_create(:name => 'member-team-propagate')

      assert d.add_members u1, :edit
      assert d.add_members t, :view
      assert d.save
      assert d.run_jobs
      assert_equal :edit, d.role_for(u1)
      assert_equal :edit, explicit_role_for(d, u1)
      assert_equal :view, d.role_for(t)
      assert_equal :view, explicit_role_for(d, t)

      assert t.add_members u1, :view
      assert t.save
      assert t.run_jobs
      assert d.reload
      assert_equal :edit, d.role_for(u1)
      assert_equal :edit, explicit_role_for(d, u1)

      assert t.add_members u1, :admin
      assert t.save
      assert t.run_jobs
      assert d.reload
      assert_equal :edit, d.role_for(u1)
      assert_equal :edit, explicit_role_for(d, u1)

      assert t.remove_members u1
      assert t.save
      assert t.run_jobs
      assert d.reload
      assert_equal :edit, d.role_for(u1)
      assert_equal :edit, explicit_role_for(d, u1)
  end

  def test_lowered_team_permission_propagates
      Domain.where(:namespace => 'test').delete
      assert d = Domain_create(:namespace => 'test')

      CloudUser.where(:login => 'team-member-1').delete
      assert u1 = CloudUser_create(:login => 'team-member-1')

      # Set up a team with one member
      Team.where(:name => 'member-team-propagate').delete
      assert t = Team_create(:name => 'member-team-propagate')
      assert t.add_members u1, :admin
      assert t.save
      assert t.run_jobs

      assert d.add_members u1, :view
      assert d.save
      assert d.run_jobs
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)
      assert d.reload
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)

      assert d.add_members t, :edit
      assert d.save
      assert d.run_jobs
      assert_equal :edit, d.role_for(t)
      assert_equal :edit, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)
      assert d.reload
      assert_equal :edit, d.role_for(t)
      assert_equal :edit, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)

      assert d.add_members t, :view
      assert d.save
      assert d.run_jobs
      assert_equal :view, d.role_for(t)
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)
      assert d.reload
      assert_equal :view, d.role_for(t)
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)

      assert d.remove_members t
      assert d.save
      assert d.run_jobs
      assert_equal nil, d.role_for(t)
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)
      assert d.reload
      assert_equal nil, d.role_for(t)
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)

      assert d.remove_members u1
      assert d.save
      assert d.run_jobs
      assert_equal nil, d.role_for(u1)
      assert d.reload 
      assert_equal nil, d.role_for(u1)
  end

  def test_raised_team_permission_propagates
      Domain.where(:namespace => 'test').delete
      assert d = Domain_create(:namespace => 'test')

      CloudUser.where(:login => 'team-member-1').delete
      assert u1 = CloudUser_create(:login => 'team-member-1')

      # Set up a team with one member
      Team.where(:name => 'member-team-propagate').delete
      assert t = Team_create(:name => 'member-team-propagate')
      assert t.add_members u1, :admin
      assert t.save
      assert t.run_jobs

      assert d.add_members u1, :view
      assert d.save
      assert d.run_jobs
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)
      assert d.reload
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)

      assert d.add_members t, :view
      assert d.save
      assert d.run_jobs
      assert_equal :view, d.role_for(t)
      assert_equal :view, explicit_role_for(d, t)
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)
      assert d.reload
      assert_equal :view, d.role_for(t)
      assert_equal :view, explicit_role_for(d, t)
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)

      assert d.add_members t, :edit
      assert d.save
      assert d.run_jobs
      assert_equal :edit, d.role_for(t)
      assert_equal :edit, explicit_role_for(d, t)
      assert_equal :edit, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)
      assert d.reload
      assert_equal :edit, d.role_for(t)
      assert_equal :edit, explicit_role_for(d, t)
      assert_equal :edit, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)

      assert d.remove_members t
      assert d.save
      assert d.run_jobs
      assert_equal nil, d.role_for(t)
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)
      assert d.reload
      assert_equal nil, d.role_for(t)
      assert_equal :view, d.role_for(u1)
      assert_equal :view, explicit_role_for(d, u1)

      assert d.remove_members u1
      assert d.save
      assert d.run_jobs
      assert_equal nil, d.role_for(u1)
      assert d.reload
      assert_equal nil, d.role_for(u1)
  end

  def test_member_team_destroy
    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser_create(:login => 'team-member-1')

    CloudUser.where(:login => 'team-member-2').delete
    assert u2 = CloudUser_create(:login => 'team-member-2')

    # Set up a team with one member
    Team.where(:name => 'member-team-destroy').delete
    assert t = Team_create(:name => 'member-team-destroy')
    assert t.add_members u1, :admin
    assert t.save
    assert t.run_jobs

    # Ensure membership expands to the domain with the team role
    d.add_members t, :edit
    assert d.save, d.inspect
    assert d.run_jobs
    assert_equal 2, d.members.count, d.inspect
    assert_equal :edit, d.role_for(t)
    assert_equal :edit, explicit_role_for(d, t)
    assert_equal :edit, d.role_for(u1)
    assert_equal nil,   explicit_role_for(d, u1)
    assert d.reload
    assert_equal 2, d.members.count
    assert_equal :edit, d.role_for(t)
    assert_equal :edit, explicit_role_for(d, t)
    assert_equal :edit, d.role_for(u1)
    assert_equal nil,   explicit_role_for(d, u1)

    # Add a member explicitly to the domain
    assert d.add_members u2, :view
    assert d.save, d.inspect
    assert d.run_jobs
    assert_equal :view, d.role_for(u2)
    assert_equal :view, explicit_role_for(d, u2)

    # Add the same member to the team
    assert t.add_members u2, :view
    assert t.save
    assert t.run_jobs

    # Ensure team membership grants higher role to user which is also an explicit domain member
    assert d.reload
    assert_equal 3, d.members.count
    assert_equal :edit, d.role_for(u2)
    assert_equal :view, explicit_role_for(d, u2)

    # Ensure membership expands to the domain with the lowered team role
    d.add_members t, :view
    assert d.save, d.inspect
    assert d.run_jobs
    assert_equal 3, d.members.count, d.inspect
    assert d.reload
    assert_equal 3, d.members.count
    assert_equal :view, d.role_for(t)
    assert_equal :view, explicit_role_for(d, t)
    assert_equal :view, d.role_for(u1)
    assert_equal nil,   explicit_role_for(d, u1)
    assert_equal :view, d.role_for(u2)
    assert_equal :view, explicit_role_for(d, u2)

    # Ensure membership expands to the domain with the raised team role
    d.add_members t, :edit
    assert d.save, d.inspect
    assert d.run_jobs
    assert_equal 3, d.members.count, d.inspect
    assert d.reload
    assert_equal 3, d.members.count
    assert_equal :edit, d.role_for(t)
    assert_equal :edit, explicit_role_for(d, t)
    assert_equal :edit, d.role_for(u1)
    assert_equal nil,   explicit_role_for(d, u1)
    assert_equal :edit, d.role_for(u2)
    assert_equal :view, explicit_role_for(d, u2)

    # Ensure we can't destroy the team directly when it is a domain member
    assert_raise(RuntimeError) { t.destroy }
    assert t.destroy_team

    # Ensure team members are removed from the domain, and explicit domain members go back to their lowered roles
    assert d.reload
    assert_equal 1, d.members.count
    assert_equal nil,   d.role_for(t)
    assert_equal nil,   d.role_for(u1)
    assert_equal :view, d.role_for(u2)
    assert_equal :view, explicit_role_for(d, u2)
  end

  def test_team_accessible_to_owner
    CloudUser.where(:login => 'owner').delete
    assert u1 = CloudUser_create(:login => 'owner')

    CloudUser.where(:login => 'non-owner').delete
    assert u2 = CloudUser_create(:login => 'non-owner')

    # Set up a team with one member
    Team.where(:name => 'owned_team').delete
    assert t = Team_create(:name => 'owned_team', :owner => u1)

    assert_equal [t], Team.accessible(u1).to_a
    assert_equal [], Team.accessible(u2).to_a
  end

  def test_team_accessible_to_member

    CloudUser.where(:login => 'owner').delete
    assert owner = CloudUser_create(:login => 'owner')

    CloudUser.where(:login => 'member').delete
    assert u1 = CloudUser_create(:login => 'member')

    CloudUser.where(:login => 'non-member').delete
    assert u2 = CloudUser_create(:login => 'non-member')

    # Set up a team with one member
    Team.where(:name => 'test_team').delete
    assert t = Team_create(:name => 'test_team', :owner_id => owner.id)
    assert t.add_members u1, :view
    assert t.save
    assert t.run_jobs

    assert_equal [t], Team.accessible(u1).to_a
    assert_equal [], Team.accessible(u2).to_a
  end

  def test_team_accessible_to_fellow_domain_member

    CloudUser.where(:login => 'owner').delete
    assert owner = CloudUser_create(:login => 'owner')

    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test')

    CloudUser.where(:login => 'domain-member').delete
    assert u1 = CloudUser_create(:login => 'domain-member')

    CloudUser.where(:login => 'non-domain-member').delete
    assert u2 = CloudUser_create(:login => 'non-domain-member')

    # Set up a team with one member
    Team.where(:name => 'test_team').delete
    assert t = Team_create(:name => 'test_team', :owner_id => owner.id)

    d.add_members [u1, t], :view
    d.save
    d.run_jobs

    assert_equal [t], Team.accessible(u1).to_a
    assert_equal [], Team.accessible(u2).to_a
  end

  def test_duplicate_global_team
    Team.where(:name => 'test-team').delete
    assert t = Team_create(:name => "test-team", :maps_to => "test-group")
    #make sure the validation does not prevent team save
    t.reload
    assert t.valid?
    assert t.save
    t = Team.new(name: "test-team")
    assert_raise(Moped::Errors::OperationFailure) {t.save}
    t = Team.new(name: "myteam", maps_to: "test-group")
    assert t.invalid?

    CloudUser.where(:login => 'team-owner-1').delete
    assert u = CloudUser_create(:login => 'team-owner-1')
    t = Team.new(name: "test-team", owner_id: u.id)
    assert t.valid?
    assert t = Team_create(:name => "test-team", :owner_id => u.id)
  end

  private
    def Domain_create(opts={})
      add_to_delete(:domains, Domain.create(opts))
    end

    def Team_create(opts={})
      add_to_delete(:teams, Team.create(opts))
    end

    def CloudUser_create(opts={})
      add_to_delete(:users, CloudUser.create(opts))
    end

    def add_to_delete(type, obj)
      (@to_delete[type] ||= []) << obj
      obj
    end
end
