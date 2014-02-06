ENV["TEST_NAME"] = "functional_access_controlled_test"
require_relative '../test_helper'

class AccessControlledTest < ActiveSupport::TestCase

  setup do 
    Lock.stubs(:lock_application).returns(true)
    Lock.stubs(:unlock_application).returns(true)
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
    Rails.configuration.stubs(:openshift).returns(:gear_sizes => [:small], :max_members_per_resource => 1)
    d = Domain.new
    d.add_members('a','b')
    assert !d.save
    assert_equal "You are limited to 1 members per domain", d.errors[:members].first, d.errors.to_hash
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

    assert_raise(Mongoid::Errors::DocumentNotFound){ d.remove_members('test') }
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
  
  def test_user_access_controllable
    CloudUser.where(:login => 'propagate_test').delete
    u = CloudUser.create(:login => 'propagate_test')

    assert_equal nil, CloudUser.member_type
    assert_equal [u], CloudUser.members_of(u._id)
    assert_equal [u], CloudUser.members_of([u._id])
    assert_equal [u], CloudUser.members_of([u])

    d = Domain.new
    assert CloudUser.members_of(d).empty?
    d.members << u.as_member
    assert_equal [u], CloudUser.members_of(d).to_a
  end

  def test_scopes_restricts_access
    u = CloudUser.find_or_create_by(:login => 'scope_test')
    Authorization.create(:expires_in => 100){ |token| token.user = u }

    #u2 = CloudUser.find_or_create_by(:login => 'scope_test_other')
    Domain.where(:namespace => 'test').delete
    d = Domain.find_or_create_by(:namespace => 'test', :owner => u)
    Domain.where(:namespace => 'test2').delete
    d2 = Domain.find_or_create_by(:namespace => 'test2', :owner => u)

    Application.where(:name => 'scopetest').delete
    assert a = Application.create(:name => 'scopetest', :domain => d)
    Application.where(:name => 'scopetest2').delete
    assert a2 = Application.create(:name => 'scopetest2', :domain => d2)

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
    assert_equal [d2._id], Domain.accessible(u).map(&:_id)
    assert CloudUser.accessible(u).empty?
    assert Authorization.accessible(u).empty?

    assert Application.find_by_user(u, 'scopetest2')
  end

  def test_broker_key_auth_scopes
    u = CloudUser.find_or_create_by(:login => 'scope_test')

    #u2 = CloudUser.find_or_create_by(:login => 'scope_test_other')
    Domain.where(:namespace => 'test').delete
    d = Domain.find_or_create_by(:namespace => 'test', :owner => u)
    Domain.where(:namespace => 'test2').delete
    d2 = Domain.find_or_create_by(:namespace => 'test2', :owner => u)

    Application.where(:name => 'scopetest2').delete
    assert a2 = Application.create(:name => 'scopetest2', :domain => d2)

    Application.where(:name => 'scopetestjenkins').delete
    assert j = Application.create(:name => 'scopetestjenkins', :domain => d)
    Application.where(:name => 'scopetestbuilder').delete
    assert b = Application.create(:name => 'scopetestbuilder', :builder_id => j._id, :domain => d)
    Application.where(:name => 'scopetestapp').delete
    assert a = Application.create(:name => 'scopetestapp', :domain => d)

    apps = [a,j,b]

    s = Scope::Scopes([Scope::DomainBuilder.new(j), Scope::Application.new(:id => j._id, :app_scope => :scale)])
    u.scopes = s
    with_membership do
      assert_equal ['scopetestapp', 'scopetestbuilder', 'scopetestjenkins'], Application.accessible(u).map(&:name).sort

      allows = {
        :change_gear_quota => [false, false, true],
        :ssh_to_gears      => [false, false, true],
        :scale_cartridge   => [false, true,  true],
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

    assert d = Domain.create(:namespace => 'test')
    u = CloudUser.create(:login => 'propagate_test')
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
    assert_equal [[u._id, :admin, nil, "propagate_test"]], op.members_added
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
    assert_equal [u._id], op.members_removed
    assert_nil op.members_added

    d.run_jobs
    assert d.pending_ops.empty?
    assert Domain.find_by(:namespace => 'test').pending_ops.empty?
  end

  def test_domain_propagates_changes_to_new_applications
    CloudUser.in(:login => ['propagate_test', 'propagate_test_2', 'propagate_test_3', 'propagate_test_4']).delete
    assert u = CloudUser.create(:login => 'propagate_test')
    assert u2 = CloudUser.create(:login => 'propagate_test_2')
    assert u3 = CloudUser.create(:login => 'propagate_test_3')
    assert u4 = CloudUser.create(:login => 'propagate_test_4')

    Domain.where(:namespace => 'test').delete
    assert d = Domain.create(:namespace => 'test', :owner => u)
    d.add_members(u2, :edit)
    d.add_members(u3, :view)
    d.add_members(u4, :admin)
    d.save

    Application.where(:name => 'propagatetest').delete
    assert a = Application.create(:name => 'propagatetest', :domain => d)

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

    assert u = CloudUser.create(:login => 'propagate_test')
    assert_equal Member.new(_id: u._id), u.as_member
    assert u2 = CloudUser.create(:login => 'propagate_test_2')
    assert u3 = CloudUser.create(:login => 'propagate_test_3')

    assert d = Domain.create(:namespace => 'test', :owner => u)
    assert_equal [Member.new(_id: u._id)], d.members
    assert_equal [['owner', :admin]], d.members.first.from
    assert d.members.first.valid?
    assert_equal Domain.default_role, d.members.first.role

    assert a = Application.create(:name => 'propagatetest', :domain => d)
    assert_equal [Member.new(_id: u._id)], d.members
    assert_equal [['domain', :admin]], a.members.first.from
    assert_equal Application.default_role, a.members.first.role

    assert     Application.accessible(u).first
    assert_nil Application.accessible(u2).first
    assert_nil Application.accessible(u3).first

    a.add_members(u2, :view)

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
    assert jobs.length == 1
    assert_equal ChangeMembersOpGroup, jobs.first.class
    assert_equal [[u2._id, :admin, nil, 'propagate_test_2'], [u3._id, :admin, nil, 'propagate_test_3']], jobs.last.members_added

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

    assert jobs.length == 2
    assert_equal ChangeMembersOpGroup, jobs.last.class
    assert_equal [u3._id], jobs.last.members_removed

    assert_equal 1, (a.members & d.members).length
    assert_equal 2, a.members.length
    assert_equal [], a.members.last.from
    assert  a.members.last.explicit_role?
    assert  a.members.include?(u2.as_member)
    assert !a.members.include?(u3.as_member)

    assert d.pending_ops.empty?
    assert Domain.find_by(:namespace => 'test').pending_ops.empty?
  end
end
