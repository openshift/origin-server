require File.expand_path('../../../test_helper', __FILE__)

class RestApiMembershipTest < ActiveSupport::TestCase
  include RestApiAuth

  setup{ with_configured_user }

  def test_retrieve_membership
    setup_domain
    assert members = @domain.members
    assert_equal 1, members.length
    assert members.first.owner
    assert_equal @user.login, members.first.name
    assert_equal User.find(:one, :as => @user).id, members.first.id
    assert_equal 'admin', members.first.role
    assert_nil members.first.explicit_role
  end

  def test_server_rejects_invalid_members
    @other = new_named_user('other')
    other = User.find :one, :as => @other

    setup_domain
    assert members = @domain.members
    assert_equal 1, members.length

    assert !@domain.update_members([Member.new(:id => other.id)])
    assert Array(@domain.errors[:base]).any?{ |s| s =~ /You must provide a role for each member/ }, @domain.errors.full_messages.join(' ')

    assert !@domain.update_members([Member.new(:id => 'unknown/unknown', :role => 'admin')])
    assert Array(@domain.errors[:base]).any?{ |s| s =~ /The specified user was not found/ }, @domain.errors.full_messages.join(' ')

    assert !@domain.update_members([Member.new(:login => '', :role => 'admin')])
    assert Array(@domain.errors[:base]).any?{ |s| s =~ /Each member must have an id or a login/ }, @domain.errors.full_messages.join(' ')

    assert !@domain.update_members([Member.new(:role => 'admin')])
    assert Array(@domain.errors[:base]).any?{ |s| s =~ /Each member must have an id or a login/ }, @domain.errors.full_messages.join(' ')
  end

  def test_add_and_remove_domain_members
    @other = new_named_user('other')
    other = User.find :one, :as => @other

    setup_domain

    # Add by id
    assert @domain.update_members([Member.new(:id => other.id, :role => 'admin')])
    assert m = @domain.members.find{ |m| m.id == other.id }
    assert_equal 'admin', m.role
    assert_equal 'admin', m.explicit_role
    assert_equal other.login, m.name

    # Destroy by element_path
    assert m.destroy
    assert_equal [@user.login], @domain.reload.members.map(&:name)

    # Add by login
    assert @domain.update_members([Member.new(:login => other.login, :role => 'edit')])
    assert m = @domain.members.find{ |m| m.id == other.id }
    assert_equal 'edit', m.role
    assert_equal 'edit', m.explicit_role
    assert_equal other.login, m.name

    # Only removal by id is currently supported
    assert !@domain.update_members([Member.new(:login => other.login, :role => 'none')])
    assert Array(@domain.errors[:base]).any?{ |s| s =~ /You must provide an id for each member with role \'none\'/ }, @domain.errors.full_messages.join(' ')

    # Destroy by login and PATCH
    assert @domain.update_members([Member.new(:id => other.id, :role => 'none')]), @domain.errors.full_messages.join(' ')
    assert_equal [@user.login], @domain.reload.members.map(&:name)
  end
end