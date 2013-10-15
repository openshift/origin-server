# Test the OpenShift::ApplicationContainer::Kerberos module
#
#
require 'test/unit'

require 'parseconfig'

require 'openshift-origin-node/model/application_container_ext/kerberos'

include OpenShift::Runtime::ApplicationContainerExt::Kerberos

#
# The K5login class depends on the ApplicationContainer instance passed in
# Specifically it uses the uuid and container_dir attributes
#
#class OpenShift::Runtime::ApplicationContainer
class Container

  attr_reader :uuid, :container_dir

  def initialize(uuid, container_dir)
    @uuid = uuid
    @container_dir = container_dir
  end

end

class TestK5login < Test::Unit::TestCase

  # Test object initialization with default values
  #
  def test_initialize_default
    
    username = 'aabbccddeeff00112233445566778899'
    homedir = '/home/' + username
    container = Container.new(username, homedir)
    
    k = K5login.new(container)

    # All explicit 
    assert_same(container, k.container, "K5login container not set correctly")
    assert_equal(username, k.username, "K5login username not set correctly")
    assert_equal('/etc/krb5.conf', k.config_file, 
                 "K5login configuration file not defaulted correctly")
    assert_equal(homedir + "/.k5login", k.filename,
                 "K5login principal file name not defaulted correctly")

  end

  # Test object initialization with explicit values
  #
  def test_initialize_explicit
    
    username = 'aabbccddeeff00112233445566778899'
    homedir = '/home/' + username
    container = Container.new(username, homedir)
    
    config_file = File.expand_path "test/unit/data/krb5.conf"
    filename = File.expand_path "test/unit/tmp/test_k5login"

    k = K5login.new(container, config_file, filename)

    assert_same(container, k.container, "K5login container not set correctly")
    assert_equal(username, k.username, "K5login username not set correctly")
    assert_equal(config_file, k.config_file, 
                 "K5login configuration file not set correctly")
    assert_equal(filename, k.filename,
                 "K5login principal file name not set correctly")

  end

  # Test object initialization with a config file
  #
  # Three cases:
  #   Config file does not exist: return to defaults
  #   Config file exists, k5login_directory not set: return to defaults
  #   Config file exists, k5login_directory set: append username to path
  # 
  def test_init_config_file

    username = 'aabbccddeeff00112233445566778899'
    homedir = '/home/' + username
    container = Container.new(username, homedir)

    
    nonexistent = "/no/such/file"
    exists_unset = "/dev/null"
    exists_set = File.expand_path "test/unit/data/krb5.conf-k5login_directory"

    k_no_conf = K5login.new(container, nonexistent)
    assert_equal(homedir + "/.k5login", k_no_conf.filename,
      "K5login principal file name not set correctly: krb5.conf does not exist")

    k_unset = K5login.new(container, exists_unset)
    assert_equal(homedir + "/.k5login", k_unset.filename,
      "K5login principal file name not set correctly: krb5.conf exists")

    k_set = K5login.new(container, exists_set)
    assert_equal("/random/location/" + username, k_set.filename,
      "K5login principal file name not set correctly: krb5.conf override")
    
  end
  
  def test_k5login_file

  end

  def test_add_principal

  end

  def test_remove_principal

  end

  def test_replace_principals

  end

  def test_modify

  end

end
