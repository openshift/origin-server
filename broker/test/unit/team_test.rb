require_relative '../test_helper'

class TeamTest < ActiveSupport::TestCase

  setup do 
    Lock.stubs(:lock_application).returns(true)
    Lock.stubs(:unlock_application).returns(true)
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
    assert t = Team.create(:name => 'non-member-team-destroy')
    assert t.destroy
  end

  def test_remove_twice
    # TODO: A remove op shouldn't fail because the member has already been removed
  end

  def test_readd_doesnt_duplicate_grants
    # TODO: Add a team with members with :view permission
    # Readd a team with :edit permission
    # Ensure there are not duplicate grants from the team
  end

  def test_adding_to_elevated_team_elevates
      Domain.where(:namespace => 'test').delete
      assert d = Domain.create(:namespace => 'test')

      CloudUser.where(:login => 'team-member-1').delete
      assert u1 = CloudUser.create(:login => 'team-member-1')

      # Set up a team with no members
      Team.where(:name => 'member-team-propagate').delete
      assert t = Team.create(:name => 'member-team-propagate')

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
      assert d = Domain.create(:namespace => 'test')

      CloudUser.where(:login => 'team-member-1').delete
      assert u1 = CloudUser.create(:login => 'team-member-1')

      # Set up a team with no members
      Team.where(:name => 'member-team-propagate').delete
      assert t = Team.create(:name => 'member-team-propagate')

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
      assert d = Domain.create(:namespace => 'test')

      CloudUser.where(:login => 'team-member-1').delete
      assert u1 = CloudUser.create(:login => 'team-member-1')

      # Set up a team with one member
      Team.where(:name => 'member-team-propagate').delete
      assert t = Team.create(:name => 'member-team-propagate')
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
      assert d = Domain.create(:namespace => 'test')

      CloudUser.where(:login => 'team-member-1').delete
      assert u1 = CloudUser.create(:login => 'team-member-1')

      # Set up a team with one member
      Team.where(:name => 'member-team-propagate').delete
      assert t = Team.create(:name => 'member-team-propagate')
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
    assert d = Domain.create(:namespace => 'test')

    CloudUser.where(:login => 'team-member-1').delete
    assert u1 = CloudUser.create(:login => 'team-member-1')

    CloudUser.where(:login => 'team-member-2').delete
    assert u2 = CloudUser.create(:login => 'team-member-2')

    # Set up a team with one member
    Team.where(:name => 'member-team-destroy').delete
    assert t = Team.create(:name => 'member-team-destroy')
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
    assert u1 = CloudUser.create(:login => 'owner')

    CloudUser.where(:login => 'non-owner').delete
    assert u2 = CloudUser.create(:login => 'non-owner')

    # Set up a team with one member
    Team.where(:name => 'owned_team').delete
    assert t = Team.create(:name => 'owned_team', :owner => u1)

    assert_equal [t], Team.accessible(u1).to_a
    assert_equal [], Team.accessible(u2).to_a
  end

  def test_team_accessible_to_member
    CloudUser.where(:login => 'member').delete
    assert u1 = CloudUser.create(:login => 'member')

    CloudUser.where(:login => 'non-member').delete
    assert u2 = CloudUser.create(:login => 'non-member')

    # Set up a team with one member
    Team.where(:name => 'test_team').delete
    assert t = Team.create(:name => 'test_team')
    assert t.add_members u1, :view
    assert t.save
    assert t.run_jobs

    assert_equal [t], Team.accessible(u1).to_a
    assert_equal [], Team.accessible(u2).to_a
  end

  def test_team_accessible_to_fellow_domain_member
    Domain.where(:namespace => 'test').delete
    assert d = Domain.create(:namespace => 'test')

    CloudUser.where(:login => 'domain-member').delete
    assert u1 = CloudUser.create(:login => 'domain-member')

    CloudUser.where(:login => 'non-domain-member').delete
    assert u2 = CloudUser.create(:login => 'non-domain-member')

    # Set up a team with one member
    Team.where(:name => 'test_team').delete
    assert t = Team.create(:name => 'test_team')

    d.add_members [u1, t], :view
    d.save
    d.run_jobs

    assert_equal [t], Team.accessible(u1).to_a
    assert_equal [], Team.accessible(u2).to_a
  end

end