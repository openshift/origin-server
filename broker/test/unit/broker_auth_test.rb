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

  def mock_access(carts=['jenkins-1'])
    app = mock('app')
    user = mock('user')
    t = Time.new

    app.stubs(:_id).returns("51ed4adbb8c2e70a72000294")
    app.stubs(:name).returns("foo")
    app.stubs(:domain_id).returns("51ed4adbb8c2e70a72000000")
    app.expects(:created_at).at_least_once.returns(t)
    app.expects(:owner).returns(user)
    app.expects(:requires).returns(carts)
    app.stubs(:downloaded_cartridges).returns({})

    Application.expects(:find).with(app._id).returns(app)

    [app, user]
  end

  def test_broker_auth_for_jenkins
    app, user = mock_access
    iv,token = svc.generate_broker_key(app)
    assert auth = svc.validate_broker_key(iv,token)
    assert_equal user, auth[:user]
    assert_equal :broker_auth, auth[:auth_method]
    assert_equal [Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => :scale), Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => :report_deployments), Scope::DomainBuilder.new(app)], auth[:scopes]
  end

  def test_broker_auth
    app, user = mock_access([])
    iv,token = svc.generate_broker_key(app)
    assert auth = svc.validate_broker_key(iv,token)
    assert_equal user, auth[:user]
    assert_equal :broker_auth, auth[:auth_method]
    assert_equal [Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => :scale), Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => :report_deployments)], auth[:scopes]
  end


  def test_legacy_broker_auth
    app = mock('app')
    user = mock('user')
    t = Time.new

    user.stubs(:login).returns('1')

    app.stubs(:_id).returns("51ed4adbb8c2e70a72000294")
    app.stubs(:domain_id).returns("51ed4adbb8c2e70a72000000")
    app.stubs(:name).returns("foo")
    app.expects(:created_at).at_least_once.returns(t)
    app.expects(:requires).returns(['jenkins-1'])
    app.expects(:downloaded_cartridges).returns({})

    Application.expects(:find_by_user).with(user, "foo").at_least_once.returns(app)
    CloudUser.expects(:find_by_identity).at_least_once.returns(user)

    legacy_json = {:app_name => app.name, :creation_time => app.created_at, svc.send(:token_login_key) => user.login }.to_json
    Hash.any_instance.expects(:to_json).returns(legacy_json)

    iv,token = svc.generate_broker_key(app)
    assert auth = svc.validate_broker_key(iv,token)
    assert_equal user, auth[:user]
    assert_equal :broker_auth, auth[:auth_method]
    assert_equal [Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => :scale), Scope::Application.new(:id => '51ed4adbb8c2e70a72000294', :app_scope => :report_deployments), Scope::DomainBuilder.new(app)], auth[:scopes]
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
