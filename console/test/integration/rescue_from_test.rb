require File.expand_path('../../test_helper', __FILE__)

class RescueFromTest < ActionDispatch::IntegrationTest
  setup { open_session }

  def with_user
  end

  def controller_raises(exception)
    with_configured_user
    ConsoleIndexController.any_instance.expects(:index).raises(exception)
    with_rescue_from do
      get '/', nil, {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, @user.password)}
    end
  end

  def default_error_message
    /An error has occurred/i
  end

  def assert_error_page(title=default_error_message)
    assert_response :success
    assert_select 'h1', title

    assert assigns(:reference_id)
    assert_select 'p', /#{assigns(:reference_id)}/
  end

  test 'render not found if domain missing' do
    controller_raises(RestApi::ResourceNotFound.new(Domain.model_name,nil))
    assert_error_page(/Domain does not exist/)
  end

  test 'render unexpected error page' do
    controller_raises(ActiveResource::ConnectionError.new(nil))
    assert_error_page
  end
end
