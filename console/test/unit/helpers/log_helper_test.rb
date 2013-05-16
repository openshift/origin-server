require File.expand_path('../../../test_helper', __FILE__)

class LogHelperTest < ActionView::TestCase
  include Console::LogHelper

  def setup
    Rails.logger = MiniTest::Mock.new
    @request = ActionController::TestRequest.new
  end

  def request
    @request
  end

  def stub_and_verify(*args)
    @request.stub :uuid, 4 do
      Time.stub :new, Time.at(0) do
        user_action(:test_action, *args)
      end
    end

    Rails.logger.verify
  end

  test 'empty options' do
    Rails.logger.expect(:info, nil, ['[user_action] SUCCESS DATE=1969-12-31 TIME=18:00:00 ACTION=TEST_ACTION USER_AGENT=Rails Testing IP_ADDRESS=0.0.0.0 REQUEST_ID=4'])

    stub_and_verify
  end

  test 'failure log' do
    Rails.logger.expect(:info, nil, ['[user_action] FAILURE DATE=1969-12-31 TIME=18:00:00 ACTION=TEST_ACTION USER_AGENT=Rails Testing IP_ADDRESS=0.0.0.0 REQUEST_ID=4'])

    stub_and_verify(false)
  end

  test 'additional options' do
    Rails.logger.expect(:info, nil, ['[user_action] SUCCESS DATE=1969-12-31 TIME=18:00:00 ACTION=TEST_ACTION USER_AGENT=Rails Testing IP_ADDRESS=0.0.0.0 REQUEST_ID=4 FOO=bar BAR=foo'])

    stub_and_verify(true, {:foo => 'bar', :bar => 'foo'})
  end

  test 'additional message' do
    Rails.logger.expect(:info, nil, ['[user_action] SUCCESS DATE=1969-12-31 TIME=18:00:00 ACTION=TEST_ACTION USER_AGENT=Rails Testing IP_ADDRESS=0.0.0.0 REQUEST_ID=4 FOO=bar More info here'])

    stub_and_verify(true, {:foo => 'bar'}, 'More info here')
  end
end
