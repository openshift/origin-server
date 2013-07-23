require File.expand_path('../../test_helper', __FILE__)
require 'tmpdir'

class BrokerAuthTest < Test::Unit::TestCase
  def setup
    test_key_dir = Dir.mktmpdir
    system "/usr/bin/openssl genrsa -out #{test_key_dir}/server_priv.pem 2048"
    system "/usr/bin/openssl rsa    -in  #{test_key_dir}/server_priv.pem -pubout > #{test_key_dir}/server_pub.pem"
    @auth_service = OpenShift::Auth::BrokerKey.new({
      :pubkeyfile => "#{test_key_dir}/server_pub.pem",
      :privkeyfile => "#{test_key_dir}/server_priv.pem",
    })
  end

  def svc
    @auth_service
  end

  def test_broker_auth
    app = mock('app')
    user = mock('user')
    domain = mock('domain')
    domains = [domain]
    t = Time.new

    user.expects(:domains).returns(domains)
    user.expects(:login).returns('1')

    domain.expects(:owner).returns(user)

    app.expects(:uuid).at_least_once.returns("51ed4adbb8c2e70a72000294")
    app.expects(:name).at_least_once.returns("foo")
    app.expects(:canonical_name).at_least_once.returns("foo")
    app.expects(:domain).returns(domain)
    app.expects(:created_at).at_least_once.returns(t)

    CloudUser.expects(:find_by_identity).at_least_once.returns(user)
    domain.expects(:applications).at_least_once.returns([app])

    iv,token = svc.generate_broker_key(app)
    assert auth = svc.validate_broker_key(iv,token)
    assert_equal user, auth[:user]
    assert_equal :broker_auth, auth[:auth_method]
    assert_equal [Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => :scale), Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => :build)], auth[:scopes]
  end

  def test_authenticate_request_passes_through
    svc.expects(:validate_broker_key).never
    svc.authenticate_request(stub(:request => stub(:request_parameters => {'broker_auth_key' => '1'}, :headers => {})))
  end

  def test_authenticate_request_checks_broker_key_parameters
    svc.expects(:validate_broker_key).with('2', '1').returns(true)
    svc.authenticate_request(stub(:request => stub(:request_parameters => {'broker_auth_key' => '1', 'broker_auth_iv' => '2'}, :headers => {})))
  end

  def test_authenticate_request_checks_broker_key_headers
    svc.expects(:validate_broker_key).with('2', '1').returns(true)
    svc.authenticate_request(stub(:request => stub(:request_parameters => {}, :headers => {'broker_auth_key' => '1', 'broker_auth_iv' => '2'})))
  end
end
