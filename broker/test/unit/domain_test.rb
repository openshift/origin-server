require 'test_helper'
require 'openshift-origin-controller'
require 'mocha'

class DomainTest < ActiveSupport::TestCase

  def setup
    OpenShift::DnsService.provider=OpenShift::DnsService
  end

  test "create and find domain" do
    ns = "ns" + gen_uuid[0..12]
    orig_d = Domain.new(namespace: ns)
    observer_seq = sequence("observer_seq")
    Domain.expects(:notify_observers).with(:domain_create_success, orig_d).in_sequence(observer_seq).once
    orig_d.save!
    d = Domain.find_by(canonical_namespace: ns.downcase)
    assert_equal_domains(orig_d, d)
  end

  test "delete cloud domain" do
    ns = "ns" + gen_uuid[0..12]
    orig_d = Domain.new(namespace: ns)
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
    orig_d = Domain.new(namespace: ns)
    orig_d.save!

    observer_seq = sequence("observer_seq")
    Domain.expects(:notify_observers).with(:domain_update_success, orig_d).in_sequence(observer_seq).once
    orig_d.update_namespace(ns + "new")
    orig_d.save!

    new_d = Domain.find_by(canonical_namespace: ns.downcase + "new")
    assert_equal_domains(orig_d, new_d)
  end
  
  test "add remove user" do
    ns = "ns" + gen_uuid[0..9]
    d = Domain.new(namespace: ns)
    d.save!

    cu = CloudUser.new(login: ns)
    cu.save!

    d.add_user(cu)

    assert d.user_ids.include?(cu._id)
    d = Domain.find_by(namespace: ns)
    assert d.user_ids.include?(cu._id)

    d.remove_user(cu)
    assert !d.user_ids.include?(cu._id)
  end
  
  def assert_equal_domains(domain1, domain2)
    assert_equal(domain1.namespace, domain2.namespace)
    assert_equal(domain1.canonical_namespace, domain2.canonical_namespace)
    assert_equal(domain1._id, domain2._id)
  end

end
