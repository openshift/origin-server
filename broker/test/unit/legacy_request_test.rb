require 'test_helper'
require 'openshift-origin-controller'

class LegacyRequestTest < ActiveSupport::TestCase
  test "Request validation for unknown request keys" do
    req = LegacyRequest.new.from_json('{"foo": "bar"}')
    assert req.invalid?
    assert 1, req.errors[:base][0][:exit_code]
  end
  
  test "Request validation: rhlogin" do
    invalid_chars = '"$^<>|%/;:,\*=~'
    invalid_chars.length.times do |i|
      req = LegacyRequest.new.from_json("{'rhlogin': 'test#{invalid_chars[i].chr}sometime'}")
      assert req.invalid?
      assert 107, req.errors[:rhlogin][0][:exit_code]
    end
    
    req = LegacyRequest.new.from_json('{"rhlogin": "kraman@redhat.com"}')
    assert req.valid?
  end
  
  test "Request validation: app_uuid" do
    invalid_chars = '"$^<>|%/;:,\*=~@'
    invalid_chars.length.times do |i|
      req = LegacyRequest.new.from_json("{'app_uuid': 'test#{invalid_chars[i].chr}sometime'}")
      assert req.invalid?
      assert 1, req.errors[:app_uuid][0][:exit_code]
    end
    
    req = LegacyRequest.new.from_json('{"app_uuid": "abcdef0123456789"}')
    assert req.valid?
  end
  
  test "Request validation: app_name" do
    invalid_chars = '"$^<>|%/;:,\*=~@ '
    invalid_chars.length.times do |i|
      req = LegacyRequest.new.from_json("{'app_name': 'test#{invalid_chars[i].chr}sometime'}")
      assert req.invalid?
      assert 1, req.errors[:app_name][0][:exit_code]
    end
    
    req = LegacyRequest.new.from_json('{"app_name": "abcdef0123456789"}')
    assert req.valid?
  end
  
  test "Request validation: node_profile" do
    ["small"].each do |n|
      req = LegacyRequest.new.from_json("{\"node_profile\": \"#{n}\"}")
      assert req.valid?
    end
  end
  
  test "Request validation: cartridge" do
    invalid_chars = '"$^<>|%/;:,\*=~@ '
    invalid_chars.length.times do |i|
      req = LegacyRequest.new.from_json("{'cartridge': 'test#{invalid_chars[i].chr}sometime'}")
      assert req.invalid?
      assert 1, req.errors[:cartridge][0][:exit_code]
    end
    
    req = LegacyRequest.new.from_json('{"cartridge": "abcd-1.2.3.4"}')
    assert req.valid?
  end
  
  test "Request validation: cart_type" do
    ["standalone","embedded"].each do |t|
      req = LegacyRequest.new.from_json("{\"cart_type\": \"#{t}\"}")
      assert req.valid?
    end
    
    req = LegacyRequest.new.from_json('{"cart_type": "other"}')
    assert req.invalid?
  end
  
  test "Request validation: action" do
    invalid_chars = '"$^<>|%/;:,\*=~@ '
    invalid_chars.length.times do |i|
      req = LegacyRequest.new.from_json("{'action': 'test#{invalid_chars[i].chr}sometime'}")
      assert req.invalid?
      assert 111, req.errors[:action][0][:exit_code]
    end
    
    req = LegacyRequest.new.from_json('{"action": "anaction"}')
    assert req.valid?
  end
  
  test "Request validation: server_alias" do
    invalid_chars = '"$^<>|%/;:,\*=~@ '
    invalid_chars.length.times do |i|
      req = LegacyRequest.new.from_json("{'server_alias': 'test#{invalid_chars[i].chr}sometime'}")
      assert req.invalid?
      assert 105, req.errors[:server_alias][0][:exit_code]
    end
    
    req = LegacyRequest.new.from_json('{"server_alias": "a-z_y.b.c.d"}')
    assert req.valid?
  end
  
  test "Request validation: key_name" do
    invalid_chars = '"$^<>|%/;:,\*=~@-. '
    invalid_chars.length.times do |i|
      req = LegacyRequest.new.from_json("{'key_name': 'test#{invalid_chars[i].chr}sometime'}")
      assert req.invalid?
      assert 106, req.errors[:key_name][0][:exit_code]
    end
    
    req = LegacyRequest.new.from_json('{"key_name": "key01"}')
    assert req.valid?
  end
end
