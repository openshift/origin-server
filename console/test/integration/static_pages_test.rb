require File.expand_path('../../test_helper', __FILE__)

class RescueFromTest < ActionDispatch::IntegrationTest
  setup { open_session }
  setup do 
    @prev = Rails.application.config.action_dispatch.show_exceptions
    Rails.application.config.action_dispatch.show_exceptions = true
  end
  teardown { Rails.application.config.action_dispatch.show_exceptions = @prev }

  def with_user
  end

  def controller_raises(exception)
    with_configured_user
    ConsoleIndexController.any_instance.expects(:index).raises(exception)
    get '/', nil, {'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, @user.password)}
  end

  test 'render not found if domain missing' do
    controller_raises(RestApi::ResourceNotFound.new(Domain.model_name,nil))

    assert_response :success
    assert_select 'h1', /Domain does not exist/

    assert assigns(:reference_id)
    assert_select 'p', /#{assigns(:reference_id)}/
  end

  test 'render unexpected error page' do
    controller_raises(ActiveResource::ConnectionError.new(nil))

    assert_response :success
    assert_select 'h1', /An error has occurred/

    assert assigns(:reference_id)
    assert_select 'p', /#{assigns(:reference_id)}/
  end

end
