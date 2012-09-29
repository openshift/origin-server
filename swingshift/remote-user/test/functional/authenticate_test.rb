require 'test_helper'

class RemoteUserAuthServiceTest < ActionController::TestCase

  def setup
    @auth_service = Swingshift::RemoteUserAuthService.new

    @request.env["Accept"] = "application/json"
  end

  def test_authenticate_success
    @request.env["REMOTE_USER"] = "test"
    data = @auth_service.authenticate(@request, "test", "test")
    assert_equal data[:auth_method], :login
    assert_equal data[:username], "test"
  end

  def test_authenticate_failure
    assert_raise StickShift::AccessDeniedException do
      data = @auth_service.authenticate(@request, "foo", "bar")
    end
  end
end
