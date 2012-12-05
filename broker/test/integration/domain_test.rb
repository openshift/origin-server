require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class DomainTest < ActiveSupport::TestCase

  def setup
    OpenShift::DnsService.provider=OpenShift::DnsService
  end

  test "create" do
    login = "user_" + gen_uuid
    cu = CloudUser.new(login: login)
    cu.save
    ns = "namespace_" + gen_uuid
    orig_d = Domain.new(ns, cu)
    orig_d.save
    d = Domain.find(cu, orig_d.uuid)
    assert_equal_domains(orig_d, d)
  end
  
  def assert_equal_domains(domain1, domain2)
    assert_equal(domain1.namespace, domain2.namespace)
    assert_equal(domain1.uuid, domain2.uuid)
    assert_equal(domain1.user.login, domain2.user.login)
  end

end
