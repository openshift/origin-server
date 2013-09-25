require File.expand_path('../../../test_helper', __FILE__)

class RestApiAuthorizationTest < ActiveSupport::TestCase
  include RestApiAuth

  def setup
    with_configured_user
  end

  test 'authorization not found returns message' do 
    m = response_messages(RestApi::ResourceNotFound){ Authorization.find("_missing!_", :as => @user) }
    assert_messages 1, /authorization/i, /not found/i, m
  end

  test 'create authorization' do
    assert a = Authorization.create(:as => @user)
    assert a.token.present?
    assert a.created_at > 10.seconds.ago
    assert a.note.blank?
    assert a.expires_in_seconds > 100
    assert a.expires_in - a.expires_in_seconds < 2
    assert !a.expired?
    assert a.scopes.length > 0
    assert a.scopes.include?('userinfo')
    assert a.identity.present?
  end

  test 'authorization allows authentication' do
    assert a = Authorization.create(:as => @user)
    assert User.find(:one, :as => a)
  end

  test 'uses reasonable expiration limit' do
    assert a = Authorization.create(:expires_in => 10.minutes.seconds, :as => @user)
    assert_equal 10.minutes.seconds, a.expires_in
  end

  test 'limits expiration' do
    assert a = Authorization.create(:as => @user)
    assert b = Authorization.create(:expires_in => 10.years.seconds, :as => @user)
    assert_equal a.expires_in, b.expires_in
  end

  test 'negative expiration' do
    assert a = Authorization.create(:expires_in => -1, :as => @user)
    assert a.expires_in > 0
  end

  test 'expiration with a string' do
    assert a = Authorization.create(:expires_in => 'abc', :as => @user)
    assert a.expires_in > 0
  end

  test 'reuse authorization' do
    assert a = Authorization.create(:as => @user)
    assert b = Authorization.create(:reuse => true, :as => @user)
    assert_equal b.id, a.id
  end

  test 'reuse needs identical scopes' do
    assert a = Authorization.create(:as => @user)
    assert b = Authorization.create(:scope => :session, :reuse => true, :as => @user)
    assert_not_equal b.id, a.id
  end

  test 'reuse needs identical notes' do
    assert a = Authorization.create(:as => @user)
    assert b = Authorization.create(:note => 'bar', :reuse => true, :as => @user)
    assert_not_equal b.id, a.id
  end

  test 'create session authorization' do
    assert a = Authorization.create(:scopes => :session, :as => @user)
    assert a.scopes.include?('session')
  end

  test 'server rejects duplicate scopes' do
    assert a = Authorization.create(:scopes => 'session session', :as => @user)
    assert_equal ['session'], a.scopes
  end

  test 'server rejects invalid scopes' do
    assert a = Authorization.create(:scopes => 'session2', :as => @user)
    assert !a.persisted?
    assert a.errors[:scopes].first =~ /One or more of the scopes you provided are not allowed. Valid scopes are session,/
  end

  test 'authorizations list changes' do
    assert_difference 'Authorization.all(:as => @user).count' do
      Authorization.create :as => @user
    end
    auths = Authorization.all(:as => @user)
    auth = auths.last
    assert auth.token.present?
  end

  test 'authorizations list does not show expired tokens' do
    auth = Authorization.create :expires_in => 1, :as => @user
    sleep(2)
    auths = Authorization.all(:as => @user)
    assert !auths.find{ |a| a.id == auth.id }, auths.inspect
  end

  test 'read scope rejects modifications and access to auth list' do
    assert auth = Authorization.create(:scopes => 'read', :as => @user)
    assert_equal ['read'], auth.scopes
    assert Domain.all :as => @user
    assert_raises(ActiveResource::ResourceInvalid){ Domain.new(:id => new_uuid, :as => auth).save! }
    assert_raises(ActiveResource::ForbiddenAccess){ Authorization.all :as => auth }
  end

  test 'authorization delete by id' do
    assert auth = Authorization.create(:as => @user)
    assert auth.destroy
  end

  test 'authorization delete by token' do
    assert auth = Authorization.create(:as => @user)
    auth = Authorization.new({:id => auth.token, :as => @user}, true)
    assert auth.destroy
    assert_raises(RestApi::ResourceNotFound){ auth.reload }
  end

  test 'authorization delete by token fails when token has no scope' do
    assert auth = Authorization.create(:as => @user)
    auth = Authorization.new({:id => auth.token, :as => auth}, true)
    assert !auth.destroy
    assert error = auth.errors[:base].first
    assert error["not allowed"]
  end

  test 'authorization delete by token when token has session scope succeeds' do
    assert auth = Authorization.create(:scope => 'session', :as => @user)
    assert auth.persisted?, auth.errors.full_messages.join("\n")
    auth = Authorization.new({:id => auth.token, :as => auth}, true)
    assert auth.destroy
    assert_raises(ActiveResource::UnauthorizedAccess){ auth.reload }
  end

  test 'authorization delete all' do
    assert Authorization.create(:as => @user)
    assert Authorization.destroy_all(:as => @user)
    assert Authorization.all(:as => @user).empty?
  end

  test 'update authorization' do
    assert a = Authorization.create(:note => 'foo', :as => @user)
    a.note = 'bar'
    assert a.save
    assert_equal 'bar', Authorization.first(:as => @user).note
  end
end
