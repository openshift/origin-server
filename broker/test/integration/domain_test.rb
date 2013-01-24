require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class DomainTest < ActiveSupport::TestCase

  def setup
    OpenShift::DnsService.provider=OpenShift::DnsService
  end

  test "create and find domain" do
    ns = "ns" + gen_uuid[0..12]
    orig_d = Domain.new(namespace: ns, canonical_namespace: ns.downcase)
    orig_d.save!
    d = Domain.find_by(canonical_namespace: ns.downcase)
    assert_equal_domains(orig_d, d)
  end

  test "delete cloud domain" do
    ns = "ns" + gen_uuid[0..12]
    orig_d = Domain.new(namespace: ns, canonical_namespace: ns.downcase)
    orig_d.save!

    orig_d.delete

    d = nil
    begin
      d = Domain.find_by(canonical_namespace: ns.downcase)
    rescue Mongoid::Errors::DocumentNotFound
      # do nothing
    end
    
    assert_equal(nil, d)
  end

  test "update domain" do
    ns = "ns" + gen_uuid[0..9]
    orig_d = Domain.new(namespace: ns, canonical_namespace: ns.downcase)
    orig_d.save!

    orig_d.set(:canonical_namespace, ns.downcase + "new")
    orig_d.set(:namespace, ns + "new")

    new_d = Domain.find_by(canonical_namespace: ns.downcase + "new")
    assert_equal_domains(orig_d, new_d)
  end
  
  def assert_equal_domains(domain1, domain2)
    assert_equal(domain1.namespace, domain2.namespace)
    assert_equal(domain1.canonical_namespace, domain2.canonical_namespace)
    assert_equal(domain1._id, domain2._id)
  end

end
