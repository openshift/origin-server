require File.expand_path('../../../test_helper', __FILE__)

class RestApiKeyTest < ActiveSupport::TestCase
  include RestApiAuth

  def setup
    with_configured_user
    once :remove_keys do
      user = @user
      lambda { Key.find(:all, :as => user).map(&:destroy) rescue nil }
    end
  end
  def teardown
    cleanup_domain
  end

  def unique_name
    super "#{uuid}%i"
  end

  def test_key_get_all
    assert Key.find :all, :as => @user
  end

  def test_key_first
    assert_equal Key.first(:as => @user), Key.find(:all, :as => @user)[0]
  end

  def test_key_create
    assert_difference('Key.find(:all, :as => @user).length', 1) do
      key = Key.new :type => 'ssh-rsa', :name => unique_name, :content => unique_name, :as => @user
      assert key.save, key.errors.inspect
    end
  end

  def test_invalid_key_create
    assert_difference('Key.find(:all, :as => @user).length', 0) do
      key = Key.new :type => 'ssh-rsa', :name => "invalid_name#{uuid}", :content => uuid, :as => @user
      assert !key.save
    end
  end

  def test_key_server_validation
    key = Key.new :as => @user
    assert !key.save(:validate => false) # don't check client validations
    assert !key.errors.empty?
    assert_equal ['Key name is required and cannot be blank.'], key.errors[:name]
    assert_equal ['Key content is required and cannot be blank.'], key.errors[:content]
    assert_equal ['Type is required and cannot be blank.'], key.errors[:type]
  end

  def test_key_delete
    key = nil
    assert_difference('Key.find(:all, :as => @user).length', 1) do
      key = Key.new :type => 'ssh-rsa', :name => unique_name, :content => unique_name, :as => @user
      assert key.save, key.errors.inspect
    end
    assert_difference('Key.find(:all, :as => @user).length', -1) do
      key.destroy
    end
  end

  def test_user_get
    user = User.find :one, :as => @user
    assert user
    assert_equal @user.login, user.login
  end

  def test_key_list
    key = Key.new :raw_content => "ssh-rsa #{unique_name}", :name => unique_name, :as => @user
    assert key.save, key.errors.inspect

    keys = Key.find :all, :as => @user
    assert keys.length > 0
    assert found_key = keys.find {|k| k.name == key.name }
    assert_attr_equal key, found_key
  end
end
