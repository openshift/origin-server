require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class DomainTest < ActiveSupport::TestCase

  def setup
    OpenShift::DnsService.provider=OpenShift::DnsService
  end

  test "create" do
    ns = "ns_" + gen_uuid[0..12]
    orig_d = Domain.new(namespace: ns)
    orig_d.save!
    d = Domain.find(orig_d._id)
    assert_equal_domains(orig_d, d)
  end
  
  def assert_equal_domains(domain1, domain2)
    assert_equal(domain1.namespace, domain2.namespace)
    assert_equal(domain1._id, domain2._id)
  end

end
