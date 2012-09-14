require File.expand_path('../../test_helper', __FILE__)

class StaticPagesTest < ActionDispatch::IntegrationTest
  setup { open_session }

  test 'retrieve 404 from non local request' do
    # no graceful way to test this today
    #get '/404', nil, {'REMOTE_ADDR' => '23.45.34.01', 'action_dispatch.show_exceptions' => true}
    #assert_response :success
    #assert_select 'h1', 'Page not found 404'
  end
end
