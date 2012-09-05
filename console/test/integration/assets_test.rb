require File.expand_path('../../test_helper', __FILE__)

class AssetsTest < ActionDispatch::IntegrationTest
  setup { open_session }

  test 'retrieve the main javascript resource' do
    get '/assets/console.js'
    assert_response :success
    assert_equal 'application/javascript', @response.content_type
    assert @response.body.length > 10*1024
    assert @response.body.include?("jQuery")
  end

  test 'retrieve an image' do
    get '/assets/sprite-vert.png'
    assert_response :success
    assert_equal 'image/png', @response.content_type
    assert @response.body.length > 1*1024
  end

  test 'retrieve common.css' do
    get '/assets/common.css'
    assert_response :success
    assert_equal 'text/css', @response.content_type
    assert @response.body.length > 20*1024
  end

  test 'retrieve origin.css' do
    get '/assets/origin.css'
    assert_response :success
    assert_equal 'text/css', @response.content_type
    assert @response.body.length > 20*1024
  end
end
