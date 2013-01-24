require 'test_helper'

class ApplicationTest < ActiveSupport::TestCase
  include OpenShift

  def setup
    super

    #setup test user auth on the mongo db
    system "/usr/bin/mongo localhost/openshift_broker_dev --eval 'db.addUser(\"openshift\", \"mooo\")' 2>&1 > /dev/null"
  end

  test "create find update delete application" do
    ns = "ns" + gen_uuid[0..12]
    app_name = "app" + gen_uuid[0..12]

    orig_d = Domain.new(namespace: ns, canonical_namespace: ns.downcase)
    orig_d.save!

    orig_app = Application.new(domain: orig_d, name: app_name, canonical_name: app_name.downcase)
    orig_app.save!

    app = Application.find_by(canonical_name: app_name.downcase)

    assert_equal(app.name, orig_app.name)
    assert_equal(app.domain.namespace, orig_app.domain.namespace)

    app.push(:aliases, "app.foo.bar")

    updated_app = Application.find_by(canonical_name: app_name.downcase)
    assert_equal(app.name, orig_app.name)
    assert_equal(app.aliases.length, updated_app.aliases.length)
    assert_equal(app.aliases[0], updated_app.aliases[0])

    app.delete

    deleted_app = nil
    begin
      deleted_app = Application.find_by(canonical_name: app_name.downcase)
    rescue Mongoid::Errors::DocumentNotFound
      # ignore
    end
    assert_equal(deleted_app, nil)
  end

end
