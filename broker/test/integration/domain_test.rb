ENV["TEST_NAME"] = "integration_domain_test"
require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class DomainTest < ActiveSupport::TestCase

  def setup
    OpenShift::DnsService.provider=OpenShift::DnsService
  end

  test "test observer is called on domain create" do
    ns = "ns" + gen_uuid[0..12]
    orig_d = Domain.new(namespace: ns)
    observer_seq = sequence("observer_seq")
    Domain.expects(:notify_observers).with(:domain_create_success, orig_d).in_sequence(observer_seq).once
    orig_d.save!
    d = Domain.find_by(canonical_namespace: ns.downcase)
    assert_equal_domains(orig_d, d)
  end


  test "test observer is called on domain update" do
    ns = "ns" + gen_uuid[0..9]
    orig_d = Domain.new(namespace: ns)
    orig_d.save!

    observer_seq = sequence("observer_seq")
    Domain.expects(:notify_observers).with(:domain_update_success, orig_d).in_sequence(observer_seq).once
    orig_d.update_namespace(ns + "new")
    orig_d.save!

    new_d = Domain.find_by(canonical_namespace: ns.downcase + "new")
    assert_equal_domains(orig_d, new_d)
  end
  
  
  def assert_equal_domains(domain1, domain2)
    assert_equal(domain1.namespace, domain2.namespace)
    assert_equal(domain1.canonical_namespace, domain2.canonical_namespace)
    assert_equal(domain1._id, domain2._id)
  end

end
