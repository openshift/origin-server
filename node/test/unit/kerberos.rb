# Test the OpenShift::ApplicationContainer::Kerberos module
#
#
require 'test/unit'

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

  def test_initialize
    
    container = Container.new("aabbccddeeff00112233445566778899",
                              "/home/testuser1")
    
    config_file = "test/data/krb5.conf"
    filename = "/tmp/test_k5login"

    k = K5login.new(container, config_file, filename)


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
