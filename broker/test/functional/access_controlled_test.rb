ENV["TEST_NAME"] = "functional_access_controlled_test"
require_relative '../test_helper'

class AccessControlledTest < ActiveSupport::TestCase

  setup do
    Lock.stubs(:lock_app).returns(true)
    Lock.stubs(:unlock_app).returns(true)
    @to_delete = {}
  end

  teardown do
    [:apps,:teams,:domains,:users].each do |type|
      Array(@to_delete[type]).each do |obj|
        obj.reload.delete rescue nil
      end
    end
  end

  def with_membership(&block)
    yield
  end

  def without_membership(&block)
    # do nothing
  end

  def test_member_equivalent
    assert_equal Member.new(_id: 'a'), Member.new(_id: 'a')
    assert_equal Member.new(_id: 'a'), CloudUser.new{ |u| u._id = 'a' }
    assert CloudUser.new{ |u| u._id = 'a' } != Member.new(_id: 'a')

    assert_equal :edit, CloudUser.new{ |u| u._id = 'a' }.as_member(:edit).role
  end

  def test_member_max
    Rails.configuration.stubs(:openshift).returns(:gear_sizes => [:small], :max_members_per_resource => 1, :max_teams_per_resource => 10)
    d = Domain.new
    d.add_members('a','b')
    assert !d.save
    assert_equal "You are limited to 1 members per domain", d.errors[:members].first, d.errors.to_hash
  end

  def test_team_max
    Rails.configuration.stubs(:openshift).returns(:gear_sizes => [:small], :max_members_per_resource => 10, :max_teams_per_resource => 0)
    d = Domain.new
    Team.where(:name => 'test').delete
    t = Team_create(:name => 'test')
    d.add_members(t, 'b')
    assert !d.save
    assert_equal "You are limited to 0 teams per domain", d.errors[:members].first, d.errors.to_hash
  end

  def test_member_explicit_remove
    d = Domain.new

    # add a member with an explicit role
    d.add_members 'a', :view
    assert_equal 1, d.members.length
    assert_equal 'a', d.members.first.id
    assert_equal :view, d.members.first.role
    assert_equal :view, d.members.first.explicit_role
    assert d.members.first.explicit_role?

    # add the same with a from role
    d.add_members 'a', :edit, [:domain]
    assert_equal 1, d.members.length
    assert_equal 'a', d.members.first.id
    assert_equal :edit, d.members.first.role
    assert_equal :view, d.members.first.explicit_role
    assert d.members.first.explicit_role?

    # remove the explicit role, ensure member still exists but without an explicit role
    d.remove_members 'a'
    assert_equal 1, d.members.length
    assert_equal 'a', d.members.first.id
    assert_equal :edit, d.members.first.role
    assert_equal nil, d.members.first.explicit_role
    assert !d.members.first.explicit_role?

    d.remove_members 'a', [:domain]
    assert_equal 0, d.members.length
  end

  def test_member_explicit
    m = Member.new(_id: 'a', role: :view)
    assert_equal :view, m.role
    assert m.explicit_role?
    assert_equal :view, m.explicit_role

    m = Member.new(_id: 'a', role: :view){ |m| m.explicit_role = :admin }
    assert_equal :view, m.role
    assert m.explicit_role?
    assert_equal :admin, m.explicit_role

    m = Member.new(_id: 'a', role: :view){ |m| m.from = [['domain', :view]]; m.explicit_role = :admin }
    assert_equal :view, m.role
    assert m.explicit_role?
    assert_equal :admin, m.explicit_role

    m = Member.new(_id: 'a', role: :view){ |m| m.from = [['domain', :view]] }
    assert_equal :view, m.role
    assert !m.explicit_role?
    assert_nil m.explicit_role
  end

  def test_member_merge_implicit
    m = Member.new(_id: 'a', role: :view)
    assert_equal :view, m.role
    assert_same m, m.merge(Member.new(role: :admin){ |m| m.from = [['domain', :admin]] })
    assert_equal :admin, m.role
    assert_equal [['domain', :admin]], m.from
    assert m.explicit_role?
    assert_equal :view, m.explicit_role

    assert !m.remove_grant(:domain)
    assert_equal :view, m.role
    assert m.from.blank?
    assert m.explicit_role?
    assert_equal :view, m.explicit_role

    assert m.remove_grant
    assert m.remove_grant # verify that removing a user twice is still true
  end

  def test_member_merge_overrides_grant_from_identical_source
    m1 = Member.new(_id: 'a', role: :admin){|m| m.from = [['domain', :admin]] }
    m2 = Member.new(_id: 'a', role: :view){|m| m.from = [['domain', :view]] }
    assert_equal :admin, m1.role
    assert_equal :view, m2.role
    m1.merge(m2)
    assert_equal :view, m1.role
    assert_equal [['domain', :view]], m1.from
    assert !m1.explicit_role?
  end

  def test_member_merge_explicit
    m = Member.new(_id: 'a', role: :admin){ |m| m.from = [['domain', :admin]] }
    assert_equal :admin, m.role
    assert_same m, m.merge(Member.new(role: :view))
    assert_equal :admin, m.role
    assert_equal [['domain', :admin]], m.from
    assert m.explicit_role?
    assert_equal :view, m.explicit_role

    assert !m.remove_grant
    assert_equal :admin, m.role
    assert_equal [['domain', :admin]], m.from
    assert !m.explicit_role?
    assert_nil m.explicit_role

    assert !m.remove_grant
    assert m.remove_grant([:domain])
    assert m.from.blank?
  end

  def test_membership_changes
    u = CloudUser.new{ |u| u._id = 'test' }
    d = Domain.new
    assert d.members.empty?

    # Removing a nonexistent member is a no-op
    assert_same d, d.remove_members('test')
    assert d.atomic_updates.empty?
    assert !d.has_member_changes?

    assert_same d, d.add_members
    assert_same d, d.remove_members

    assert_same d, d.add_members('test')
    assert_equal 1, d.members.length
    assert_equal 'test', d.members.first._id

    assert d.members.last.explicit_role?
    assert_equal Domain.default_role, d.members.last.role
    assert d.members.last.valid?

    d.add_members('other', [:owner])
    assert_equal 2, d.members.length
    assert_equal 'other', d.members.last._id
    assert_equal [['owner', :admin]], d.members.last.from
    assert !d.members.last.explicit_role?

    d.add_members('other', :edit)
    assert_equal 2, d.members.length
    m = d.members.last
    assert_equal 'other', m._id
    assert_equal [['owner', :admin]], m.from
    assert m.explicit_role?
    assert_equal :edit, m.explicit_role
    assert_equal :admin, m.role

    d.remove_members('other')
    assert_equal 2, d.members.length
    assert_equal 'other', d.members.last._id
    assert_equal [['owner', :admin]], d.members.last.from
    assert !d.members.last.explicit_role?

    d.remove_members('other', [:domain])
    assert_equal 2, d.members.length

    d.remove_members('other', [:owner])
    assert_equal 1, d.members.length
    assert_equal 'test', d.members.first._id

    d.remove_members('test')
    assert d.members.empty?
    assert d.atomic_updates.empty?
    assert !d.has_member_changes?
  end

  # the oo-admin-repair and oo-admin-chk scripts provide a nil resource for
  # checking the permission as a workaround since the resource is ignored for this role 
  def test_resource_for_ssh_to_gear_role
    assert Ability.has_permission?('test', :ssh_to_gears, Application, :edit, nil)
  end

  def test_has_member_changes
    CloudUser.where(:login => 'hasmember1').delete
    assert u1 = CloudUser_create(:login => 'hasmember1')

    Domain.where(:namespace => 'hasmember').delete
    assert d = Domain_create(:namespace => 'hasmember')

    # Test no-ops
    d.add_members
    assert !d.has_member_changes?
    d.remove_members
    assert !d.has_member_changes?

    # Add a new member
    d.add_members u1, :view
    assert d.has_member_changes?
    assert d.save
    assert !d.has_member_changes?

    # Add a new grant
    d.add_members u1, :view, [:owner]
    assert d.has_member_changes?
    assert d.save
    assert !d.has_member_changes?

    # Re-add an existing explicit role and grant
    d.add_members u1, :view
    d.add_members u1, :view, [:owner]
    assert !d.has_member_changes?

    # Add a new grant with a duplicate role
    d.add_members u1, :view, [:team, 123]
    assert d.has_member_changes?
    assert d.save
    assert !d.has_member_changes?

    # Remove a grant which leaves the calculated role the same
    d.remove_members u1, [:team, 123]
    assert d.has_member_changes?
    assert d.save
    assert !d.has_member_changes?

    # Remove an explicit role which leaves the calculated role the same
    d.remove_members u1
    assert d.has_member_changes?
    assert d.save
    assert !d.has_member_changes?

    # Ensure final role matches expectations
    assert_equal :view, d.role_for(u1)
  end

  def test_team_propagation
      CloudUser.where(:login => 'teampropagate1').delete
      CloudUser.where(:login => 'teampropagate2').delete
      assert u1 = CloudUser_create(:login => 'teampropagate1')
      assert u2 = CloudUser_create(:login => 'teampropagate2')

      Team.where(:name => 'teampropagate').delete
      assert t = Team_create(:name => 'teampropagate')

      Domain.where(:namespace => 'teampropagate').delete
      assert d = Domain_create(:namespace => 'teampropagate')

      # Application created before the team is a member
      Application.where(:name => 'teampropagate1').delete
      assert a1 = Application_create(:name => 'teampropagate1', :domain => d)

      # Initial members of the team
      t.add_members u1, :admin
      t.save
      assert_equal :admin, t.role_for(u1)
      t.run_jobs

      d.add_members t, :view
      d.save
      d.run_jobs

      # Check propagation of team members when adding team
      a1.reload
      assert d_t_member = t.as_member.find_in(d.members)
      assert_equal :view,  d_t_member.role
      assert_equal nil, d_t_member.from

      assert d_u1_member = u1.as_member.find_in(d.members)
      assert_equal Set.new([["team", t._id, :view]]), Set.new(d_u1_member.from)

      # Teams do not propagate from domains to apps
      assert_raise(Mongoid::Errors::DocumentNotFound){ t.as_member.find_in(a1.members) }

      # Expect the user from attribute to just have domain info
      assert a1_u1_member = u1.as_member.find_in(a1.members)
      assert_equal Set.new([["domain", :view]]), Set.new(a1_u1_member.from)

      # Check propagation of additional team members to existing domain/app
      t.add_members u2, :admin
      t.save
      t.run_jobs

      d.reload
      a1.reload
      assert d_u2_member = u2.as_member.find_in(d.members)
      assert_equal Set.new([["team", t._id, :view]]), Set.new(d_u2_member.from)

      assert a1_u2_member = u2.as_member.find_in(a1.members)
      assert_equal Set.new([["domain", :view]]), Set.new(a1_u2_member.from)

      # Application created after the team is a member
      Application.where(:name => 'teampropagate2').delete
      assert a2 = Application_create(:name => 'teampropagate2', :domain => d)

      assert_raise(Mongoid::Errors::DocumentNotFound){ t.as_member.find_in(a2.members) }

      assert a2_u1_member = u1.as_member.find_in(a2.members)
      assert_equal Set.new([["domain", :view]]), Set.new(a2_u1_member.from)

      assert a2_u2_member = u2.as_member.find_in(a1.members)
      assert_equal Set.new([["domain", :view]]), Set.new(a2_u2_member.from)
  end

  def test_user_access_controllable
    CloudUser.where(:login => 'propagate_test').delete
    u = CloudUser_create(:login => 'propagate_test')

    Team.where(:name => 'propagate_test').delete
    t = Team_create(:name => 'propagate_test')

    assert_equal 'user', CloudUser.member_type
    assert_equal [u], CloudUser.members_of(u._id)
    assert_equal [u], CloudUser.members_of([u._id])
    assert_equal [], CloudUser.members_of(t._id)
    assert_equal [], CloudUser.members_of([t._id])
    assert_equal [u], CloudUser.members_of([u,t])

    assert_equal 'team', Team.member_type
    assert_equal [], Team.members_of(u._id)
    assert_equal [], Team.members_of([u._id])
    assert_equal [t], Team.members_of(t._id)
    assert_equal [t], Team.members_of([t._id])
    assert_equal [t], Team.members_of([u,t])

    d = Domain.new
    assert CloudUser.members_of(d).empty?
    assert Team.members_of(d).empty?
    d.members << u.as_member
    d.members << t.as_member
    assert_equal [u], CloudUser.members_of(d).to_a
    assert_equal [t], Team.members_of(d).to_a
  end

  def test_scopes_restricts_access
    CloudUser.where(:login => 'scope_test').delete
    u = CloudUser_create(:login => 'scope_test')
    Authorization.create(:expires_in => 100){ |token| token.user = u }

    #u2 = CloudUser.find_or_create_by(:login => 'scope_test_other')
    Domain.where(:namespace => 'test').delete
    d = Domain_create(:namespace => 'test', :owner => u)
    Domain.where(:namespace => 'test2').delete
    d2 = Domain_create(:namespace => 'test2', :owner => u)

    Application.where(:name => 'scopetest').delete
    assert a = Application_create(:name => 'scopetest', :domain => d)
    Application.where(:name => 'scopetest2').delete
    assert a2 = Application_create(:name => 'scopetest2', :domain => d2)

    assert Application.accessible(u).count > 0
    assert Domain.accessible(u).count > 0
    assert CloudUser.accessible(u).count > 0
    assert Authorization.accessible(u).count > 0

    u.scopes = Scope.list!("application/#{a._id}/view")
    assert_equal [a._id], Application.accessible(u).map(&:_id)
    with_membership{ assert_equal [d._id], Domain.accessible(u).map(&:_id) }
    without_membership{ assert_equal [d._id], Domain.accessible(u).map(&:_id) }
    assert CloudUser.accessible(u).empty?
    assert Authorization.accessible(u).empty?

    u.scopes = Scope.list!("application/#{a._id}/admin")
    assert CloudUser.accessible(u).present?

    u.scopes = Scope.list!("application/#{a2._id}/view")
    assert_equal [d2._id], Domain.accessible(u).map(&:_id)

    u.scopes = Scope.list!("application/#{Moped::BSON::ObjectId.new}/view")
    with_membership{ assert Application.accessible(u).empty? }
    without_membership{ assert Application.accessible(u).empty? } # test the legacy rendering path
    assert Domain.accessible(u).empty?
    assert CloudUser.accessible(u).empty?
    assert Authorization.accessible(u).empty?

    u.scopes = Scope.list!("domain/#{d._id}/view")
    assert_equal [a._id], Application.accessible(u).map(&:_id)
    assert_equal [d._id], Domain.accessible(u).map(&:_id)
    assert CloudUser.accessible(u).empty?
    assert Authorization.accessible(u).empty?

    u.scopes = Scope.list!("domain/#{d._id}/admin")
    assert CloudUser.accessible(u).present?

    u.scopes = Scope.list!("domain/#{d2._id}/view")
    assert_equal [a2._id], Application.accessible(u).map(&:_id)
    assert_equal [a2._id], Application.accessible(u).or({:_id => a._id}, {:_id => a2._id}).map(&:_id)
    assert_equal [d2._id], Domain.accessible(u).map(&:_id)
    assert_equal [d2._id], Domain.accessible(u).or({:_id => d._id}, {:_id => d2._id}).map(&:_id)
    assert CloudUser.accessible(u).empty?
    assert Authorization.accessible(u).empty?

    # Make sure multiple scopes don't stomp each other's conditions
    u.scopes = Scope.list!("domain/#{d._id}/view domain/#{d2._id}/view")
    assert_equal [a._id, a2._id].sort, Application.accessible(u).map(&:_id).sort
    assert_equal [d._id, d2._id].sort, Domain.accessible(u).map(&:_id).sort
    assert CloudUser.accessible(u).empty?
    assert Authorization.accessible(u).empty?

    assert Application.find_by_user(u, 'scopetest2')
  end

  def test_broker_key_auth_scopes
    CloudUser.where(:login => 'scope_test').delete
    u = CloudUser_create(:login => 'scope_test')

    #u2 = CloudUser.find_or_create_by(:login => 'scope_test_other')
    Domain.where(:namespace => 'test').delete
    d = Domain_create(:namespace => 'test', :owner => u)
    Domain.where(:namespace => 'test2').delete
    d2 = Domain_create(:namespace => 'test2', :owner => u)

    Application.where(:name => 'scopetest2').delete
    assert a2 = Application_create(:name => 'scopetest2', :domain => d2)

    Application.where(:name => 'scopetestjenkins').delete
    assert j = Application_create(:name => 'scopetestjenkins', :domain => d)
    Application.where(:name => 'scopetestbuilder').delete
    assert b = Application_create(:name => 'scopetestbuilder', :builder_id => j._id, :domain => d)
    Application.where(:name => 'scopetestapp').delete
    assert a = Application_create(:name => 'scopetestapp', :domain => d)

    apps = [a,j,b]

    s = Scope::Scopes([Scope::DomainBuilder.new(j), Scope::Application.new(:id => j._id, :app_scope => :scale)])
    u.scopes = s
    with_membership do
      assert_equal ['scopetestapp', 'scopetestbuilder', 'scopetestjenkins'], Application.accessible(u).map(&:name).sort

      allows = {
        :change_gear_quota => [false, false, true],
        :ssh_to_gears      => [false, false, true],
        :scale_cartridge   => [false, true,  true],
        :change_state      => [false, true,  true]
      }
      allows.each_pair do |p, expect|
        apps.zip(expect).each do |(a, bool)|
          assert_equal bool, s.authorize_action?(p, a, [], u), "Expected #{bool} for authorize_action on #{a.name} for #{p}"
        end
      end
    end
    without_membership do
      assert_equal ['scopetestapp', 'scopetestbuilder', 'scopetestjenkins'], Application.accessible(u).map(&:name).sort

      allows = {
        :change_gear_quota => [true, true, true],
        :ssh_to_gears      => [true, true, true],
        :scale_cartridge   => [true, true, true],
        :change_state      => [true, true, true]
      }
      allows.each_pair do |p, expect|
        apps.zip(expect).each do |(a, bool)|
          assert_equal bool, s.authorize_action?(p, a, [], u), "Expected #{bool} for authorize_action on #{a.name} for #{p}"
        end
      end
    end

    assert  s.authorize_action?(:create_builder_application, d, [{:domain_id => d._id}], u)
    assert !s.authorize_action?(:create_builder_application, d, [{:domain_id => d2._id}], u)
    assert !s.authorize_action?(:create_builder_application, d, [{}], u)
    assert !s.authorize_action?(:create_builder_application, d2, [], u)
  end

  def test_domain_model_consistent
    CloudUser.where(:login => 'propagate_test').delete
    Domain.where(:namespace => 'test').delete

    assert d = Domain_create(:namespace => 'test')
    u = CloudUser_create(:login => 'propagate_test')
    assert_equal Member.new(_id: u._id), u.as_member

    d.changing_members{ self.members << u.as_member }
    assert d.atomic_updates['$pushAll'].has_key?('members')
    assert d.atomic_updates['$pushAll']['members'].present?

    assert d.has_member_changes?
    assert_nil d.members.last.role

    assert !d.save

    d.members.last.role = Domain.default_role

    assert d.save
    assert d.atomic_updates.empty?
    assert_equal 1, d.pending_ops.length

    assert d.has_member?(u)
    assert u.member_of?(d)
    assert !d.has_member_changes?

    assert d2 = Domain.find_by(:namespace => 'test')
    assert_equal 1, d2.pending_ops.length
    assert op = d2.pending_ops.last
    assert_equal ChangeMembersDomainOp, op.class
    assert_equal [[u._id, CloudUser.member_type, :admin, "propagate_test"]], op.members_added
    assert_nil op.members_removed

    d.run_jobs
    assert d.pending_ops.empty?
    assert Domain.find_by(:namespace => 'test').pending_ops.empty?

    d.changing_members{ self.members.pop }
    assert d.save
    assert d.atomic_updates.empty?
    assert_equal 1, d.pending_ops.length

    assert d2 = Domain.find_by(:namespace => 'test')
    assert_equal 1, d2.pending_ops.length
    assert op = d2.pending_ops.last
    assert_equal ChangeMembersDomainOp, op.class
    assert_equal [u.as_member.to_key], op.members_removed
    assert_nil op.members_added

    d.run_jobs
    assert d.pending_ops.empty?
    assert Domain.find_by(:namespace => 'test').pending_ops.empty?
  end

  def test_members_differentiate_types
    CloudUser.where(:id => "1").delete
    CloudUser.where(:login => "propagate_test").delete
    assert u = CloudUser_create(:id => "1", :login => 'propagate_test')

    Team.where(:id => "1").delete
    Team.where(:name => "propagate_test").delete
    assert t = Team_create(:id => "1", :name => 'propagate_test')

    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test', :owner => u)
    d.add_members(u, :view)
    d.add_members(u, :edit)
    d.add_members(t, :view)
    d.add_members(t, :edit)
    d.save

    Application.where(:name => 'propagatetest').delete
    assert a = Application_create(:name => 'propagatetest', :domain => d)

    assert_equal :admin, d.role_for(u), "Role incorrect for #{d.class.model_name}"
    assert_equal :edit, d.role_for(t), "Role incorrect for #{d.class.model_name}"

    assert_equal :admin, a.role_for(u), "Role incorrect for #{a.class.model_name}"
    assert_equal nil, a.role_for(t), "Role incorrect for #{a.class.model_name}"
  end

  def test_domain_propagates_changes_to_new_applications
    CloudUser.in(:login => ['propagate_test', 'propagate_test_2', 'propagate_test_3', 'propagate_test_4']).delete
    assert u = CloudUser_create(:login => 'propagate_test')
    assert u2 = CloudUser_create(:login => 'propagate_test_2')
    assert u3 = CloudUser_create(:login => 'propagate_test_3')
    assert u4 = CloudUser_create(:login => 'propagate_test_4')

    Domain.where(:namespace => 'test').delete
    assert d = Domain_create(:namespace => 'test', :owner => u)
    d.add_members(u2, :edit)
    d.add_members(u3, :view)
    d.add_members(u4, :admin)
    d.save

    Application.where(:name => 'propagatetest').delete
    assert a = Application_create(:name => 'propagatetest', :domain => d)

    [d, a].each do |m|
      assert_equal :admin, m.role_for(u), "Role incorrect for #{m.class.model_name}"
      assert_equal :edit, m.role_for(u2), "Role incorrect for #{m.class.model_name}"
      assert_equal :view, m.role_for(u3), "Role incorrect for #{m.class.model_name}"
      assert_equal :admin, m.role_for(u4), "Role incorrect for #{m.class.model_name}"
    end
  end

  def test_domain_propagates_changes_to_application
    CloudUser.in(:login => ['propagate_test', 'propagate_test_2', 'propagate_test_3']).delete
    Domain.where(:namespace => 'test').delete
    Application.where(:name => 'propagatetest').delete
    Application.any_instance.expects(:run_jobs).twice

    assert u = CloudUser_create(:login => 'propagate_test')
    assert_equal Member.new(_id: u._id), u.as_member
    assert u2 = CloudUser_create(:login => 'propagate_test_2')
    assert u3 = CloudUser_create(:login => 'propagate_test_3')

    assert d = Domain_create(:namespace => 'test', :owner => u)
    assert_equal [Member.new(_id: u._id)], d.members
    assert_equal [['owner', :admin]], d.members.first.from
    assert d.members.first.valid?
    assert_equal Domain.default_role, d.members.first.role

    assert a = Application_create(:name => 'propagatetest', :domain => d)
    assert_equal [Member.new(_id: u._id)], d.members
    assert_equal [['domain', :admin]], a.members.first.from
    assert_equal Application.default_role, a.members.first.role

    assert     Application.accessible(u).first
    assert_nil Application.accessible(u2).first
    assert_nil Application.accessible(u3).first

    a.add_members(u2, :view)
    assert a.save
    assert jobs = a.pending_op_groups
    assert jobs.length == 1
    assert_equal ChangeMembersOpGroup, jobs.last.class
    assert_equal [[u2._id, CloudUser.member_type, :view, 'propagate_test_2']], jobs.last.members_added

    assert_equal [u], CloudUser.members_of(a){ |m| Ability.has_permission?(m._id, :ssh_to_gears, Application, m.role, a) }

    d.add_members(u2)
    d.add_members(u3)
    assert !d.atomic_updates.empty?

    assert d.save
    assert_equal 3, d.members.length

    assert Domain.accessible(u).first
    with_membership do
      assert Domain.accessible(u2).first
      assert Domain.accessible(u3).first
    end
    without_membership do
      assert_equal [], Domain.accessible(u2)
      assert_equal [], Domain.accessible(u3)
    end

    d.run_jobs

    assert Application.accessible(u).first
    with_membership do
      assert Application.accessible(u2).first
      assert Application.accessible(u3).first
    end
    without_membership do
      assert_equal [], Application.accessible(u2)
      assert_equal [], Application.accessible(u3)
    end

    assert jobs = d.applications.first.pending_op_groups
    assert jobs.length == 2
    assert_equal ChangeMembersOpGroup, jobs.last.class
    assert_equal [[u3._id, CloudUser.member_type, :admin, 'propagate_test_3']], jobs.last.members_added
    assert_equal [[u2._id, CloudUser.member_type, :view, :admin]], jobs.last.roles_changed

    a = d.applications.first
    assert_equal 3, (a.members & d.members).length
    a.members.each{ |m| assert_equal [['domain', :admin]], m.from }
    assert a.members[1].explicit_role?

    assert d.pending_ops.empty?
    assert Domain.find_by(:namespace => 'test').pending_ops.empty?

    d.remove_members(u2)
    d.remove_members(u3)
    assert d.save
    assert d.atomic_updates.empty?
    assert_equal 1, d.pending_ops.length
    assert_equal 1, d.members.length

    assert Application.accessible(u).first
    with_membership do
      assert Application.accessible(u2).first
      assert Application.accessible(u3).first
    end
    without_membership do
      assert_equal [], Application.accessible(u2)
      assert_equal [], Application.accessible(u3)
    end

    d.run_jobs

    assert_nil Application.accessible(u3).first

    a = Domain.find_by(:namespace => 'test').applications.first
    assert jobs = a.pending_op_groups

    assert jobs.length == 3
    assert_equal ChangeMembersOpGroup, jobs.last.class
    assert_equal [u3.as_member.to_key], jobs.last.members_removed

    assert_equal 1, (a.members & d.members).length
    assert_equal 2, a.members.length
    assert_equal [], a.members.last.from
    assert  a.members.last.explicit_role?
    assert  a.members.include?(u2.as_member)
    assert !a.members.include?(u3.as_member)

    assert d.pending_ops.empty?
    assert Domain.find_by(:namespace => 'test').pending_ops.empty?
  end

  def test_reentrant_member_change_ops
    Team.in(:name => 'reentrant_test').delete
    CloudUser.in(:login => ['propagate_test_1', 'propagate_test_2', 'propagate_test_3']).delete
    Domain.where(:namespace => ['test1','test2']).delete
    Application.where(:name => ['propagatetest1', 'propagatetest2']).delete

    assert u = CloudUser_create(:login => 'propagate_test_1')
    assert u2 = CloudUser_create(:login => 'propagate_test_2')
    assert u3 = CloudUser_create(:login => 'propagate_test_3')

    assert d1 = Domain_create(:namespace => 'test1', :owner => u)
    assert d2 = Domain_create(:namespace => 'test2', :owner => u)
    assert a1 = Application_create(:name => 'propagatetest1', :domain => d1)
    assert a2 = Application_create(:name => 'propagatetest2', :domain => d2)
    assert t = Team_create(:name => 'reentrant_test')

    t.add_members u, :view
    assert_equal 0, t.pending_ops.length
    t.save
    assert_equal 1, t.pending_ops.length
    t.run_jobs
    assert_equal 0, t.pending_ops.length

    [d1,d2].each do |d|
      d.add_members t, :view
      assert_equal 0, d.pending_ops.length
      d.save
      assert_equal 1, d.pending_ops.length
      d.run_jobs
      assert_equal 0, d.pending_ops.length
    end

    # An error while running an app pending op leaves the model updated in mongo, with pending ops left on the models
    Domain.expects(:accessible).at_least(0).returns([d1, d2]) # Make sure we get the domains in the order we expect
    ChangeMembersOpGroup.any_instance.expects(:execute).raises("Error")
    t.add_members u2, :view
    t.save
    assert_raise(RuntimeError) { t.run_jobs }
    assert_equal :view, t.reload.role_for(u2)
    assert_equal :view, d1.reload.role_for(u2)
    assert_equal :view, a1.reload.role_for(u2)
    assert_equal nil,   d2.reload.role_for(u2) # D2 didn't run yet
    assert_equal nil,   a2.reload.role_for(u2) # Change members op didn't run for d2 yet, so membership changes didn't get pushed to a1
    assert_equal [:init], t.pending_ops.map(&:state)      # Got put back in init state
    assert_equal [0],     t.pending_ops.map(&:queued_at)  # Got its queued_at timer reset
    assert_equal [:init], d1.pending_ops.map(&:state)     # Got put back in init state
    assert_equal [0],     d1.pending_ops.map(&:queued_at) # Got its queued_at timer reset
    assert_equal 1,       a1.pending_op_groups.length # Got queued
    assert_equal [],      d2.pending_ops.map(&:state) # No op queued up for d2 yet
    assert_equal 0,       a2.pending_op_groups.length # No op queued up for a2 yet

    # Remove the failure
    ChangeMembersOpGroup.any_instance.unstub(:execute)

    # Try to rerun the job
    assert t.run_jobs

    # Make sure everything propagated correctly
    assert_equal :view, t.reload.role_for(u2)
    assert_equal :view, d1.reload.role_for(u2)
    assert_equal :view, a1.reload.role_for(u2)
    assert_equal :view, d2.reload.role_for(u2)
    assert_equal :view, a2.reload.role_for(u2) # Membership got updated for a2
    assert_equal [], t.pending_ops
    assert_equal [], d1.pending_ops
    assert_equal [], a1.pending_op_groups
    assert_equal [], d2.pending_ops
    assert_equal [], a2.pending_op_groups
  end

  private
    def Domain_create(opts={})
      add_to_delete(:domains, Domain.create(opts))
    end

    def Team_create(opts={})
      add_to_delete(:teams, Team.create(opts))
    end

    def Application_create(opts={})
      add_to_delete(:apps, Application.create(opts))
    end

    def CloudUser_create(opts={})
      add_to_delete(:users, CloudUser.create(opts))
    end

    def add_to_delete(type, obj)
      (@to_delete[type] ||= []) << obj
      obj
    end
end
