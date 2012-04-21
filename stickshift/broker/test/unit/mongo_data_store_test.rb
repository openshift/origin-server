#require 'test_helper'
#
#class MongoDataStoreTest < ActiveSupport::TestCase
#  include Crankcase
#
#  def setup
#    super
#  end
#
#  test "create and find cloud user" do
#    ds = MongoDataStore.new
#    orig_cu = cloud_user
#    user_id = orig_cu["login"]
#    user_uuid = orig_cu["uuid"]
#    ds.create("CloudUser", user_id, nil, orig_cu)
#    cu = ds.find("CloudUser", user_id, nil)
#    assert_equal(orig_cu, cu)
#    cu = ds.find_by_uuid("CloudUser", user_uuid)
#    assert_equal(orig_cu, cu)
#  end
# 
#  test "delete cloud user" do
#    ds = MongoDataStore.new
#    cu = cloud_user
#    user_id = cu["login"]
#    ds.create("CloudUser", user_id, nil, cu)
#    ds.delete("CloudUser", user_id, nil)
#    cu = ds.find("CloudUser", user_id, nil)
#    assert_equal(nil, cu)
#  end
#  
#  test "save cloud user" do
#    ds = MongoDataStore.new
#    cu = cloud_user
#    user_id = cu["login"]
#    ds.create("CloudUser", user_id, nil, cu)
#    updates = {
#      "max_gears" => 3
#    }
#    ds.save("CloudUser", user_id, nil, updates)
#    cu["max_gears"] = 3
#    updated_cu = ds.find("CloudUser", user_id, nil)
#    assert_equal(cu, updated_cu)
#  end
#  
#  test "find all cloud users" do
#    ds = MongoDataStore.new
#    (1..2).each do |i|
#      cu = cloud_user
#      user_id = cu["login"]
#      ds.create("CloudUser", user_id, nil, cu)
#    end
#    assert(ds.find_all("CloudUser", nil).length >= 2)
#  end
#  
#  test "create and find domain" do
#    ds = MongoDataStore.new
#    cu = cloud_user
#    user_id = cu["login"]
#    ds.create("CloudUser", user_id, nil, cu)
#    orig_dom = domain
#    dom_id = orig_dom["uuid"]
#    ds.create("Domain", user_id, dom_id, orig_dom)
#    dom = ds.find("Domain", user_id, dom_id)
#    assert_equal(orig_dom, dom)
#    dom = ds.find_by_uuid("Domain", dom_id)
#    cu["domains"] = [ orig_dom ]
#    assert_equal(cu, dom)
#  end
# 
#  test "delete cloud domain" do
#    ds = MongoDataStore.new
#    cu = cloud_user
#    user_id = cu["login"]
#    ds.create("CloudUser", user_id, nil, cu)
#    orig_dom = domain
#    dom_id = orig_dom["uuid"]
#    ds.create("Domain", user_id, dom_id, orig_dom)
#    ds.delete("Domain", user_id, dom_id)
#    dom = ds.find("Domain", user_id, dom_id)
#    assert_equal(nil, dom)
#    ds.delete("CloudUser", user_id, nil)
#    cu = ds.find("CloudUser", user_id, nil)
#    assert_equal(nil, cu)
#  end
#
#=begin 
#  test "save domain" do
#    ds = MongoDataStore.new
#    cu = cloud_user
#    user_id = cu["login"]
#    ds.create("CloudUser", user_id, nil, cu)
#    orig_dom = domain
#    dom_id = orig_dom["uuid"]
#    ds.create("Domain", user_id, dom_id, orig_dom)
#    updates = {
#      "namespace" => "ns1"
#    }
#    ds.save("Domain", user_id, dom_id, updates)
#    orig_dom["namespace"] = "ns1"
#    updated_dom = ds.find("Domain", user_id, dom_id)
#    assert_equal(orig_dom, updated_dom)
#  end
#=end
#  
#  test "find all domains" do
#    ds = MongoDataStore.new
#    cu = cloud_user
#    user_id = cu["login"]
#    ds.create("CloudUser", user_id, nil, cu)
#    (1..2).each do |i|
#      orig_dom = domain
#      dom_id = orig_dom["uuid"]
#      ds.create("Domain", user_id, dom_id, orig_dom)
#    end
#    assert(ds.find_all("Domain", user_id).length >= 2)
#    assert(ds.find_all("CloudUser", nil).length >= 2)
#  end
#
#  test "create and find application" do
#    ds = MongoDataStore.new
#    
#    orig_cu = cloud_user
#    user_id = orig_cu["login"]
#    ds.create("CloudUser", user_id, nil, orig_cu)
#    orig_dom = domain
#    dom_id = domain["uuid"]
#    ds.create("Domain", user_id, dom_id, orig_dom)
#    
#    orig_a = application
#    a_uuid = orig_a['uuid']
#    ds.create("Application", user_id, orig_a["name"], orig_a)
#    a = ds.find("Application", user_id, orig_a["name"])
#    assert_equal(orig_a, a)
#    
## FIXME: Current workaround to update consumed_gears is done during gear craete/destroy
##        but not directly in mongo datastore.
#    cu = ds.find("CloudUser", user_id, nil)
##    assert_equal(1, cu['consumed_gears'])
#      
#    by_uuid_cu = ds.find_by_uuid("Application", a_uuid)
#    assert_equal(cu, by_uuid_cu)
#  end
#  
#  test "create and save application with embedded" do
#    ds = MongoDataStore.new
#    
#    cu = cloud_user
#    user_id = cu["login"]
#    ds.create("CloudUser", user_id, nil, cu)
#    orig_dom = domain
#    dom_id = domain["uuid"]
#    ds.create("Domain", user_id, dom_id, orig_dom)
#    
#    orig_a = application
#    orig_a["embedded"] = {"mysql-5.1" => {"info" => "Connection URL: mysql://..."}}
#    ds.create("Application", user_id, orig_a["name"], orig_a)
#    a = ds.find("Application", user_id, orig_a["name"])
#    assert_equal(orig_a, a)
#    
#    orig_a["embedded"] = {"mysql-5.1" => {"info" => "Connection URL: mysql://..."}}
#    ds.save("Application", user_id, orig_a["name"], orig_a)
#    a = ds.find("Application", user_id, orig_a["name"])
#    assert_equal(orig_a, a)
#    
## FIXME    
##    cu = ds.find("CloudUser", user_id, nil)
##    assert_equal(1, cu['consumed_gears'])
#  end
#  
#  test "save application" do
#    ds = MongoDataStore.new
#    
#    cu = cloud_user
#    user_id = cu["login"]
#    ds.create("CloudUser", user_id, nil, cu)
#    orig_dom = domain
#    dom_id = domain["uuid"]
#    ds.create("Domain", user_id, dom_id, orig_dom)
#    
#    orig_a = application
#    ds.create("Application", user_id, orig_a["name"], orig_a)
#    
#    b = application
#    ds.create("Application", user_id, b["name"], b)
#    
#    orig_a["aliases"] = ["www.myalias.com"]
#    ds.save("Application", user_id, orig_a["name"], orig_a)
#    a = ds.find("Application", user_id, orig_a["name"])
#    assert_equal(orig_a, a)
#    
#    ds.save("Application", user_id, orig_a["name"], orig_a)
#    a = ds.find("Application", user_id, orig_a["name"])
#    assert_equal(orig_a, a)
#    
#    apps = ds.find_all("Application", user_id)
#    assert_equal(2, apps.length)
#    
## FIXME    
##    cu = ds.find("CloudUser", user_id, nil)
##    assert_equal(2, cu['consumed_gears'])
#  end
#  
#  test "delete application" do
#    ds = MongoDataStore.new
#    
#    cu = cloud_user
#    user_id = cu["login"]
#    ds.create("CloudUser", user_id, nil, cu)
#    orig_dom = domain
#    dom_id = domain["uuid"]
#    ds.create("Domain", user_id, dom_id, orig_dom)
#    
#    a = application
#    ds.create("Application", user_id, a["name"], a)
#      
#    b = application
#    ds.create("Application", user_id, b["name"], b)
#    
#    ds.delete("Application", user_id, a["name"])
#    a = ds.find("Application", user_id, a["name"])
#    assert_equal(nil, a)
#      
#    apps = ds.find_all("Application", user_id)
#    assert_equal(1, apps.length)
#
## FIXME    
##    cu = ds.find("CloudUser", user_id, nil)
##    assert_equal(1, cu['consumed_gears'])
#  end
#  
#  test "application limits" do
#    ds = MongoDataStore.new
#    
#    cu = cloud_user
#    user_id = cu["login"]
#    ds.create("CloudUser", user_id, nil, cu)
#    orig_dom = domain
#    dom_id = domain["uuid"]
#    ds.create("Domain", user_id, dom_id, orig_dom)
#    
#    a = nil
#    (1..2).each do |i|
#      a = application
#      ds.create("Application", user_id, a["name"], a)
#    end
#        
#    apps = ds.find_all("Application", user_id)
#    assert_equal(2, apps.length)
#
## FIXME
#=begin
#    cu = ds.find("CloudUser", user_id, nil)
#    assert_equal(2, cu['consumed_gears'])
#      
#    caught_exception = false
#    begin
#      b = application
#      ds.create("Application", user_id, b["name"], b)
#    rescue Exception => e
#      caught_exception = true
#    end
#    assert(caught_exception)
#=end
#    
#    ds.delete("Application", user_id, a["name"])
#    a = ds.find("Application", user_id, a["name"])
#    assert_equal(nil, a)
#      
#    apps = ds.find_all("Application", user_id)
#    assert_equal(1, apps.length)
#    
## FIXME    
##    cu = ds.find("CloudUser", user_id, nil)
##    assert_equal(1, cu['consumed_gears'])
#      
#    a = application
#    ds.create("Application", user_id, a["name"], a)
#      
#    apps = ds.find_all("Application", user_id)
#    assert_equal(2, apps.length)
#  end
# 
#  def cloud_user
#    uuid = gen_uuid
#    cloud_user = {
#      "login" => "user_id#{uuid}",
#      "uuid" => uuid,
#      "system_ssh_keys" => {},
#      "env_vars" => {},
#      "ssh_keys" => {},
#      "max_gears" => 2,
#      "consumed_gears" => 0,
#      "vip" => false
#    }
#    cloud_user
#  end
#
#  def domain
#    uuid = gen_uuid
#    domain = {
#      "namespace" => "namespace#{uuid}",
#      "uuid" => uuid
#    }
#    domain
#  end
#  
#  def application
#    uuid = gen_uuid
#    application = {
#      "framework" => "php-5.3", 
#      "creation_time" => DateTime::now().strftime,
#      "uuid" => uuid, 
#      "embedded" => {}, 
#      "aliases" => [], 
#      "name" => "name#{uuid}", 
#      "server_identity" => "1234",
#      "uid" => nil
#    }
#    application
#  end
#
#end
