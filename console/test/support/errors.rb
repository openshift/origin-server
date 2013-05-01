module ErrorPageAssertions
  def default_not_found_message
    /not found/i
  end
  def default_error_message
    /An error has occurred/i
  end
  def default_server_unavailable_message
    /Maintenance in progress/i
  end

  def assert_not_found_page(title=default_not_found_message)
    assert_response :success
    assert_select 'h1', title
  end
  def assert_server_unavailable_page(title=default_server_unavailable_message)
    assert_response :success
    assert_select 'h1', title
  end
  def assert_error_page(title=default_error_message)
    assert_response :success
    assert_select 'h1', title

    assert assigns(:reference_id)
    assert_select 'p', /#{assigns(:reference_id)}/
  end
end

class ActionController::TestCase
  include ErrorPageAssertions
end

class ActionDispatch::IntegrationTest
  include ErrorPageAssertions
end
