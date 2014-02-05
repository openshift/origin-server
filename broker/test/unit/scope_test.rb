ENV["TEST_NAME"] = "unit_scope_test"
require File.expand_path('../../test_helper', __FILE__)

class ScopeTest < ActiveSupport::TestCase

  test 'configured expirations' do
    assert_equal 1.month.seconds, Scope.for!('userinfo').default_expiration
    assert_equal 1.month.seconds, Scope.for!('userinfo').maximum_expiration

    assert_equal 1.month.seconds, Scope.for!('read').default_expiration
    assert_equal 1.month.seconds, Scope.for!('read').maximum_expiration

    assert_equal 1.days.seconds, Scope.for!('session').default_expiration
    assert_equal 2.days.seconds, Scope.for!('session').maximum_expiration
  end

  test 'empty scope list' do
    assert Scope.list!(nil).empty?
    assert Scope.list!('').empty?
    assert Scope.list!(' ').empty?
    assert Scope.list(nil).empty?
    assert Scope.list('').empty?
    assert Scope.list(' ').empty?
  end
  test 'raise on invalid scope' do
    assert_raise(Scope::Unrecognized){ Scope.for!(nil) }
    assert_raise(Scope::Unrecognized){ Scope.for!('') }
    assert_raise(Scope::Unrecognized){ Scope.for!(' ') }
  end
  test 'return nil on invalid scope' do
    assert_nil Scope.for(nil)
    assert_nil Scope.for('')
    assert_nil Scope.for(' ')
  end
  test 'raise on invalid scope list' do
    assert_raise(Scope::Unrecognized){ Scope.list!('a') }
    assert Scope.list('a').empty?
  end
  test 'find valid scope' do
    assert (scope = Scope.for!('session')).is_a?(Scope::Session)
    assert_equal 'session', scope.to_s
    assert_equal [scope], Scope.list!('session')
    assert_equal [scope], Scope.list!(' session ')
  end

  test 'validates parameterized object id scope' do
    assert_raise(Moped::Errors::InvalidObjectId){ Scope.for!('application/a/scale') }
    assert_raise(Moped::Errors::InvalidObjectId){ Scope.for!('domain/a/admin') }
  end

  test 'find parameterized scope' do
    assert scope = Scope.for!('application/51ed4adbb8c2e70a72000294/scale')
    assert_equal :scale, scope.send(:app_scope)
    assert_equal Moped::BSON::ObjectId.from_string('51ed4adbb8c2e70a72000294'), scope.send(:id)
    assert_equal 'application/51ed4adbb8c2e70a72000294/scale', scope.to_s
    assert scope2 = Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => 'scale')
    assert_equal 'application/51ed4adbb8c2e70a72000294/scale', scope2.to_s

    assert !scope.equal?(scope2)
    assert scope == scope2
    assert_equal 0, scope <=> scope2

    assert_raise(Scope::Invalid){ Scope.list!('application/51ed4adbb8c2e70a72000294/b') }
    assert_raise(Scope::Invalid){ Scope::Application.new({}) }
    assert_raise(Scope::Invalid){ Scope::Application.new(:id => '51ed4adbb8c2e70a72000294') }
    assert_raise(Scope::Invalid){ Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => nil) }

    assert_raise(Scope::Invalid){ Scope::Domain.new(:id => '51ed4adbb8c2e70a72000294', :domain_scope => nil) }
  end

  test 'default permissions' do
    assert  Scope::Session.new.allows_action?(nil)

    assert !Scope::Base.new.allows_action?(nil)

    assert  Scope::Read.new.allows_action?(stub(:request => stub(:method => 'GET')))
    assert !Scope::Read.new.allows_action?(stub(:request => stub(:method => 'POST')))
    controller = stub(:request => stub(:method => 'GET'))
    controller.expects(:is_a?).with(AuthorizationsController).returns(true)
    assert !Scope::Read.new.allows_action?(controller)

    assert  Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => :scale).allows_action?(nil)

    assert  Scope::Domain.new(:id => '51ed4adbb8c2e70a72000001', :domain_scope => :admin).allows_action?(nil)

    assert !Scope::Userinfo.new.allows_action?(nil)
    assert !Scope::Userinfo.new.allows_action?(UserController.new)
    assert !Scope::Userinfo.new.allows_action?(stub(:is_a? => true, :action_name => 'index'))
    assert  Scope::Userinfo.new.allows_action?(stub(:is_a? => true, :action_name => 'show'))
  end

  test 'get scope array' do
    assert_equal [], Scope::Scopes(nil)
    assert Scope::Scopes(nil).is_a?(Scope::Scopes)

    assert_equal [], Scope::Scopes([])
    assert Scope::Scopes([]).is_a?(Scope::Scopes)

    assert_equal [Scope::Userinfo.new], Scope::Scopes('userinfo')
    assert Scope::Scopes('userinfo').is_a?(Scope::Scopes)
  end

  test 'authorization has a default scope' do
    assert_equal Scope.for!('userinfo'), Authorization.new.scopes
    assert_equal 'userinfo', Authorization.new.scopes
    assert_equal [Scope.for!('userinfo')], Authorization.new.scopes_list
    assert Authorization.new{ |a| a.scopes = 'foo' }.scopes_list.empty?

    a = Authorization.new
    a.scopes = nil
    assert_equal [], a.scopes_list
  end

  test 'describe_all' do
    assert d = Scope.describe_all
    assert first = d.first
    assert first[0]
    assert scope = Scope.for(first[0])
    assert_equal [scope.scope_name, scope.scope_description, scope.default_expiration, scope.maximum_expiration], first
  end

  test 'application describe' do
    # scopes are currently empty
    assert_present s = Scope::Application.describe[0]
    assert_equal 'application/:id/view', s[0]
    assert s[1] =~ /Grant read-only/
    assert s[2].is_a? Numeric
    assert s[3].is_a? Numeric
  end

  test 'domain describe' do
    # scopes are currently empty
    assert_present s = Scope::Domain.describe[0]
    assert_equal 'domain/:id/view', s[0]
    assert s[1] =~ /Grant read-only/
    assert s[2].is_a? Numeric
    assert s[3].is_a? Numeric
  end
end
