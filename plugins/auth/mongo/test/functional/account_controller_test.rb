require 'test_helper'

class AccountControllerTest < ActionController::TestCase
  def setup
    @auth_service = OpenShift::MongoAuthService.new 
    @auth_service.register_user("admin","admin")
    @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64.encode64('admin:admin')
    @request.env["Accept"] = "application/json"    
  end
  
  def teardown
    UserAccount.delete_all
  end
  
  def test_create
    post(:create, { :username => "test", :password => "test" })
    assert !@collection.find( {"_id" => "test"}).first.nil?
  end
  
  def test_authenticate
    post(:create, { :username => "test", :password => "test" })
    data = @auth_service.authenticate(ActionDispatch::TestRequest.new, "test", "test")
    assert_equal data[:auth_method], :login
    assert_equal data[:username], "test"
  end
end
