require_relative '../test_helper'

class SanitizeTest < OpenShift::NodeTestCase
  def test_sanitize_password
    result = OpenShift::Runtime::Utils.sanitize_credentials("password=foo")

    assert_equal result, "password=[HIDDEN]"
  end

  def test_sanitize_passwd
    result = OpenShift::Runtime::Utils.sanitize_credentials("passwd=foo")

    assert_equal result, "passwd=[HIDDEN]"
  end

  def test_sanitize_username 
    result = OpenShift::Runtime::Utils.sanitize_credentials("username=foo")

    assert_equal result, "username=[HIDDEN]"
  end

  def test_sanitize_user
    result = OpenShift::Runtime::Utils.sanitize_credentials("user=foo")

    assert_equal result, "user=[HIDDEN]"
  end

  def test_sanitize_credentials_no_password
    result = OpenShift::Runtime::Utils.sanitize_credentials("some string")

    assert_equal result, "some string"
  end

  def test_sanitize_credentials_invalid_utf8_chars
    result = OpenShift::Runtime::Utils.sanitize_credentials("hello\255".force_encoding('UTF-8'))

    assert_equal result, 'hello'
  end

  def test_sanitize_credentials_invalid_char_in_password
    result = OpenShift::Runtime::Utils.sanitize_credentials("pass\255word=foo".force_encoding('UTF-8'))

    assert_equal result, 'password=[HIDDEN]'
  end
end
