require File.expand_path('../../../test_helper', __FILE__)

class RestApiKeyTest < ActiveSupport::TestCase

  def setup
    with_configured_user
  end
  def teardown
    cleanup_domain
  end

  def test_key_get_all
    items = Key.find :all, :as => @user
    assert_equal 0, items.length
  end

  def test_key_first
    assert_equal Key.first(:as => @user), Key.find(:all, :as => @user)[0]
  end

  def test_key_create
    items = Key.find :all, :as => @user

    orig_num_keys = items.length

    key = Key.new :type => 'ssh-rsa', :name => "test#{@ts}", :content => @ts, :as => @user
    assert key.save

    items = Key.find :all, :as => @user
    assert_equal orig_num_keys + 1, items.length
  end

  def test_invalid_key_create
    items = Key.find :all, :as => @user

    orig_num_keys = items.length
    begin
      key = Key.new :type => 'ssh-rsa', :name => "invalid_name#{@ts}", :content => @ts, :as => @user
      key.save
      fail
    rescue
    end

    items = Key.find :all, :as => @user
    assert_equal orig_num_keys, items.length
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
    items = Key.find :all, :as => @user

    orig_num_keys = items.length

    key = Key.new :type => 'ssh-rsa', :name => "test#{@ts}", :content => @ts, :as => @user
    assert key.save

    items = Key.find :all, :as => @user
    assert_equal orig_num_keys + 1, items.length

    assert items[items.length-1].destroy

    items = Key.find :all, :as => @user
    assert_equal orig_num_keys, items.length
  end

  def test_user_get
    user = User.find :one, :as => @user
    assert user
    assert_equal @user.login, user.login
  end

  def test_key_create_without_domain
    domain = Domain.first :as => @user
    domain.destroy_recursive if domain

    key = Key.new :raw_content => 'ssh-rsa key', :name => 'default', :as => @user
    assert key.save
    assert key.errors.empty?
  end

  def test_key_create
    key = Key.new :raw_content => 'ssh-rsa key', :name => 'default', :as => @user
    assert key.save
    assert key.errors.empty?

    key.destroy
    assert_raise ActiveResource::ResourceNotFound do
      Key.find 'default', :as => @user
    end
  end

  def test_key_list
    keys = Key.find :all, :as => @user
    assert_equal [], keys
    assert_nil Key.first :as => @user

    key = Key.new :raw_content => 'ssh-rsa key', :name => 'default', :as => @user
    assert key.save
    assert key.errors.empty?
    key.messages = nil
    key.id = nil

    keys = Key.find :all, :as => @user
    assert_equal 'ssh-rsa', keys[0].type
    assert_equal 'key', keys[0].content
    assert_equal 'default', keys[0].name
    assert_equal [key], keys

    key_new = Key.find 'default', :as => @user
    assert_equal key, key_new
  end
end
