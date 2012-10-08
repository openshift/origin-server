require 'test/unit'
require 'test_helper'

class BrokerAuthTest < Test::Unit::TestCase
  def setup
    test_key_dir = "#{File.dirname(__FILE__)}/../dummy/config/"
    system "/usr/bin/openssl genrsa -out #{test_key_dir}/server_priv.pem 2048"
    system "/usr/bin/openssl rsa    -in  #{test_key_dir}/server_priv.pem -pubout > #{test_key_dir}/server_pub.pem"
    @auth_service = OpenShift::MongoAuthService.new
  end

  def test_broker_auth
    app = Mocha::Mock.new
    user = Mocha::Mock.new
    t = Time.new

    user.expects(:login).returns("foo@example.com")
    app.expects(:name).at_least_once.returns("foo")
    app.expects(:user).returns(user)
    app.expects(:creation_time).at_least_once.returns(t)

    CloudUser.expects(:find).at_least_once.returns(user)
    user.expects(:applications).at_least_once.returns([app])

    iv,token = @auth_service.generate_broker_key(app)
    @auth_service.validate_broker_key(iv,token)
  end
end
