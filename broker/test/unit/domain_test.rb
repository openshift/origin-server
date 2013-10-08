ENV["TEST_NAME"] = "unit_domain_test"
require 'test_helper'

class DomainTest < ActiveSupport::TestCase
  def setup
    @random = rand(1000000000)
    @login = "user#{@random}"
    @user = CloudUser.new(login: @login)
    @user.save
    Lock.create_lock(@user)
    stubber
  end
  
  def teardown
    begin
      @user.force_delete
    rescue
    end
  end
  
  test "namespace validation" do
    
    invalid_chars = '"$^<>|%/;:,\*=~.'
    invalid_chars.length.times do |i|
      domain = Domain.new(namespace: "ns#{@random}#{invalid_chars[i].chr}", owner:@user)
      assert domain.invalid?
      assert !domain.errors[:namespace].empty?
    end
    
    invalid_namespaces = ["ns12345678901234567890", "", "abc.xyz"]
    invalid_namespaces.each do |ns|
      domain = Domain.new(namespace: ns, owner:@user)
      assert domain.invalid?
      assert !domain.errors[:namespace].empty?
    end
  end
  
  test "create find and delete domain" do
    namespace = "ns#{@random}"
    @domain = Domain.new(namespace: namespace, owner:@user)
    @domain.save
    
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace.downcase)
    assert_equal(namespace, @domain.namespace)
    
    domains = Domain.where(owner: @user)
    assert_equal(1, domains.length)
    
    @domain.delete
    
    domains = Domain.where(owner: @user)
    assert_equal(0, domains.length)
    
  end
  
  test "add and remove ssh keys to domain" do
    namespace = "ns#{@random}"
    namespace.downcase!
    @domain = Domain.new(namespace: namespace, owner:@user)
    @domain.save
    
    @app_name = "app#{@random}"
    @app = Application.create_app(@app_name, [PHP_VERSION], @domain)
    @app.save
    
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace)
    
    key = SystemSshKey.new(name: "key1", type: "ssh-rsa", content: "ABCD")

    @domain.add_system_ssh_keys([key])
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace)
    assert_equal(1, @domain.system_ssh_keys.length)

    k = @domain.system_ssh_keys[0]
    assert_equal(key.name, k.name)
    assert_equal(key.type, k.type)
    assert_equal(key.content, k.content)

    # Check logic to avoid duplicates
    key = SystemSshKey.new(name: "key1", type: "ssh-rsa", content: "EFGH")

    @domain.add_system_ssh_keys([key])
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace)
    assert_equal(1, @domain.system_ssh_keys.length)

    k = @domain.system_ssh_keys[0]
    assert_equal(key.name, k.name)
    assert_equal(key.type, k.type)
    assert_equal(key.content, k.content)
    
    @domain.remove_system_ssh_keys([key])
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace)
    assert_equal(0, @domain.system_ssh_keys.length)
    
  end
  
  test "add and remove env variables to domain" do
    namespace = "ns#{@random}"
    namespace.downcase!
    @domain = Domain.new(namespace: namespace, owner:@user)
    @domain.save
    
    @app_name = "app#{@random}"
    @app = Application.create_app(@app_name, [PHP_VERSION], @domain)
    @app.save
    
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace)
    
    env_vars = [{"key"=>"key1", "value"=>"value1"}, {"key"=>"key2", "value"=>"value2"}]
    
    @domain.add_env_variables(env_vars)
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace)
    assert_equal(2, @domain.env_vars.length)
    assert @domain.env_vars.each_cons(env_vars.size).include? env_vars
    
    # Check logic to avoid duplicates
    @domain.add_env_variables(env_vars)
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace)
    assert_equal(2, @domain.env_vars.length)
    assert @domain.env_vars.each_cons(env_vars.size).include? env_vars

    @domain.remove_env_variables(env_vars)
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace)
    assert_equal(0, @domain.env_vars.length)
    
  end
  
  test "update domain" do
    namespace = "ns#{@random}"
    namespace.downcase!
    @domain = Domain.new(namespace: namespace, owner:@user)
    @domain.save
    
    @app_name = "app#{@random}"
    @app = Application.create_app(@app_name, [PHP_VERSION], @domain)
    @app.save
    
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace)
    
    new_namespace = "xns#{@random}"
    @domain.namespace = new_namespace
    assert_raise(OpenShift::UserException){ @domain.save_with_duplicate_check! }
    
    @app.destroy_app
    @domain = Domain.find_by(owner: @user, canonical_namespace: namespace)
    @domain.namespace = new_namespace
    @domain.save_with_duplicate_check!
    assert_raise(Mongoid::Errors::DocumentNotFound){Domain.find_by(owner: @user, canonical_namespace: namespace)}
    @domain = Domain.find_by(owner: @user, canonical_namespace: new_namespace)
    assert_equal(new_namespace, @domain.namespace)
    
  end
  

  
end
