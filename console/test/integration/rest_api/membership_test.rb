require File.expand_path('../../../test_helper', __FILE__)

class RestApiMembershipTest < ActiveSupport::TestCase
  include RestApiAuth

  setup{ with_configured_user }

  def new_named_api_user(login)
    u = new_named_user(login)
    User.find :one, :as => u
  end

  def other_user
    @other_user ||= new_named_api_user('other')
  end

  def second_user
    @second_user ||= new_named_api_user('second_other')
  end

  def third_user
    @third_user ||= new_named_api_user('third_other')
  end

  def fourth_user
    @fourth_user ||= new_named_api_user('fourth_other')
  end

  def test_retrieve_membership
    setup_domain
    assert members = @domain.members
    assert_equal 1, members.length
    assert m = members.first
    assert m.owner
    assert_equal @user.login, m.login
    assert_equal m.login, m.name
    assert_equal User.find(:one, :as => @user).id, m.id
    assert_equal 'admin', m.role
    assert_nil m.explicit_role
    assert @domain.owner?
    assert @domain.admin?
    assert_equal [{'type' => 'owner', 'role' => 'admin'}], m.from, m.from.inspect
  end

  def test_server_rejects_invalid_members
    setup_domain

    assert !@domain.update_members([m = Member.new(:id => other_user.id)])
    assert Array(m.errors[:role]).any?{ |s| s =~ /You must provide a role for each member/ }, m.errors.full_messages.join(' ')
    assert Array(@domain.errors[:members]).any?{ |s| s == 'The domain members could not be updated.' }, @domain.errors.full_messages.join(' ')

    assert !@domain.update_members([m = Member.new(:id => 'unknown/unknown', :role => 'admin')])
    assert Array(m.errors[:id]).any?{ |s| s =~ /There is no account with identifier unknown\/unknown/ }, m.errors.full_messages.join(' ')
    assert Array(@domain.errors[:members]).any?{ |s| s == 'The domain members could not be updated.' }, @domain.errors.full_messages.join(' ')

    assert !@domain.update_members([m = Member.new(:login => '', :role => 'admin')])
    assert Array(m.errors[:base]).any?{ |s| s =~ /Each member being changed must have an id or a login/ }, m.errors.full_messages.join(' ')
    assert Array(@domain.errors[:members]).any?{ |s| s == 'The domain members could not be updated.' }, @domain.errors.full_messages.join(' ')

    assert !@domain.update_members([m = Member.new(:role => 'admin')])
    assert Array(m.errors[:base]).any?{ |s| s =~ /Each member being changed must have an id or a login/ }, m.errors.full_messages.join(' ')
    assert Array(@domain.errors[:members]).any?{ |s| s == 'The domain members could not be updated.' }, @domain.errors.full_messages.join(' ')
  end

  def test_add_and_remove_domain_members
    setup_domain

    # Add by id
    assert @domain.update_members([Member.new(:id => other_user.id, :role => 'admin')])
    assert m = @domain.members.find{ |m| m.id == other_user.id }
    assert_equal 'admin', m.role
    assert_equal 'admin', m.explicit_role
    assert_equal other_user.login, m.login

    # Destroy by element_path
    assert m.destroy
    assert_equal [@user.login], @domain.reload.members.map(&:login)

    # Add by login
    assert @domain.update_members([Member.new(:login => other_user.login, :role => 'edit')])
    assert m = @domain.members.find{ |m| m.id == other_user.id }
    assert_equal 'edit', m.role
    assert_equal 'edit', m.explicit_role
    assert_equal other_user.login, m.login

    # Only removal by id is currently supported
    assert @domain.update_members([Member.new(:login => other_user.login, :role => 'none')])
    assert_equal [@user.login].sort, @domain.reload.members.map(&:login).sort

    # Destroy by login and PATCH
    assert @domain.update_members([Member.new(:login => other_user.login, :role => 'edit')])
    assert @domain.update_members([Member.new(:id => other_user.id, :role => 'none')]), @domain.errors.full_messages.join(' ')
    assert_equal [@user.login], @domain.reload.members.map(&:login)
  end

  def test_unable_to_rename_domain_as_admin
    setup_domain

    assert @domain.update_members([Member.new(:id => other_user.id, :role => 'admin')])

    # other user has admin access and can view domain
    assert d = Domain.find(@domain.id, :as => other_user)
    assert !d.owner?
    assert  d.admin?
    assert  d.editor?
    assert !d.readonly?

    d.name = 'modified'
    assert !d.save, "Was able to rename as non-owner admin"
    assert Array(d.errors[:base]).any?{ |s| s =~ /You are not permitted to perform.*change_namespace on domain.*/ }, d.errors.full_messages.join(' ')
  end

  def test_unable_to_change_domain_gear_sizes_as_admin
    setup_domain
    
    assert @domain.update_members([Member.new(:id => other_user.id, :role => 'admin')])

    # other user has admin access and can view domain
    assert d = Domain.find(@domain.id, :as => other_user)
    assert !d.owner?
    assert  d.admin?
    assert  d.editor?
    assert !d.readonly?

    d.allowed_gear_sizes = []
    assert !d.save, "Was able to change domain gear sizes as non-owner admin"
    assert Array(d.errors[:base]).any?{ |s| s =~ /You are not permitted to perform.*change_gear_sizes on domain.*/ }, d.errors.full_messages.join(' ')
  end

  def test_unable_to_delete_domain_as_admin
    setup_domain
    
    assert @domain.update_members([Member.new(:id => other_user.id, :role => 'admin')])

    # other user has admin access and can view domain
    assert d = Domain.find(@domain.id, :as => other_user)
    assert !d.owner?
    assert  d.admin?
    assert  d.editor?
    assert !d.readonly?

    assert !d.destroy, "Was able to delete domain as non-owner admin"
    assert Array(d.errors[:base]).any?{ |s| s =~ /You are not permitted to perform.*destroy on domain.*/ }, d.errors.full_messages.join(' ')
  end

  def test_able_to_add_other_members_as_admin
    setup_domain

    assert_raises(RestApi::ResourceNotFound){ Domain.find @domain, :as => other_user }
    assert @domain.update_members([Member.new(:id => other_user.id, :role => 'admin')])
    assert @domain.owner?
    assert m = @domain.members.find{ |m| m.id == other_user.id }

    # other user has admin access and can view domain
    assert_raises(RestApi::ResourceNotFound){ Domain.find(@domain, :as => second_user) }
    assert d = Domain.find(@domain.id, :as => other_user)
    d_other = d
    assert !d.owner?
    assert  d.admin?
    assert  d.editor?
    assert !d.readonly?
    assert d.update_members([Member.new(:id => second_user.id, :role => 'edit'), Member.new(:id => third_user.id, :role => 'view')])
    assert_equal 4, d.members.length

    # second user cannot grant access with the edit role
    assert d = Domain.find(@domain.id, :as => second_user)
    d_second = d
    assert !d.owner?
    assert !d.admin?
    assert  d.editor?
    assert !d.readonly?
    assert !d.update_members([Member.new(:id => fourth_user.id, :role => 'edit')])
    assert Array(d.errors[:base]).any?{ |s| s =~ /You are not permitted to perform .*change_members.*domain/ }, d.errors.full_messages.join(' ')

    # an editor can't delete members
    assert_raises(ActiveResource::ForbiddenAccess){ d_second.delete(:members) }

    # third user can view the domain but cannot do anything
    assert d = Domain.find(@domain.id, :as => third_user)
    d_third = d
    assert !d.owner?
    assert !d.admin?
    assert !d.editor?
    assert  d.readonly?

    # a viewer can't delete members
    assert_raises(ActiveResource::ForbiddenAccess){ d_third.delete(:members) }
    assert !d.destroy

    # a viewer can't change the domain
    assert_raises(ActiveResource::ResourceInvalid){ d.name = "#{d.id}_"; d.save! }
    d.reload

    # can give the owner an explicit role
    assert owner = d_other.members.find(&:owner)
    owner.role = 'edit'
    assert d_other.update_members([owner])
    assert m = d_other.members.find(&:owner)
    assert_equal 'edit', m.explicit_role
    assert_equal 'admin', m.role

    # another admin cannot delete the owner, only remove an explicit role
    assert owner = d_other.reload.members.find(&:owner)
    assert owner.destroy
    assert owner.has_exit_code?(132)
    assert m = d_other.reload.members.find(&:owner)
    assert_nil m.explicit_role
    assert_equal 'admin', m.role

    # a second remove is the same - the user no longer has an explicit role still
    assert owner.destroy
    assert owner.has_exit_code?(132)

    # remove all members
    assert @domain.reload.delete(:members)
    assert_equal [@user.login], @domain.reload.members.map(&:login)
  end
end