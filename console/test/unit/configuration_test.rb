require File.expand_path('../../test_helper', __FILE__)

#
# Mock tests only - should verify functionality of ActiveResource extensions
# and simple server/client interactions via HttpMock
#
class ConfigurationTest < ActiveSupport::TestCase
  setup do 
    @old_config = Console.instance_variable_get(:@config)
    Console.instance_variable_set(:@config, nil)
  end
  teardown{ Console.instance_variable_set(:@config, @old_config) }

  def expects_file_read(contents, file='file')
    IO.expects(:read).with(File.expand_path(file)).returns(contents)
  end

  test 'ConfigFile handles key pairs' do
    expects_file_read(<<-FILE.strip_heredoc)
      key=1
      escaped\\==2
      double_escaped\\\\=3
      escaped_value=\\4
        spaces = 5
      #comment=6

      commented_value=7 # some comments
      comm#ented_key=8
      greedy=equals=9
    FILE
    c = Console::ConfigFile.new('file')
    assert_equal({
      'key' => '1',
      'escaped=' => '2',
      'double_escaped\\' => '3',
      'escaped_value' => '4',
      'spaces' => '5',
      'commented_value' => '7',
      'greedy' => 'equals=9',
    }, c)
  end

  test 'Console.configure yields' do
    Console.configure{ @ran = true }
    assert @ran
  end

  test 'get default user agent' do
    assert Console.config.user_agent =~ /openshift_console.*?\d+\.\d+\.\d/
  end

  test 'Console.configure reads file' do
    expects_file_read(<<-FILE.strip_heredoc)
      BROKER_URL=foo
      BROKER_API_USER=bob
    FILE
    Console.configure('file')
    assert_equal 'foo', Console.config.api[:url]
    assert_equal 'bob', Console.config.api[:user]
    assert_equal 'file', Console.config.api[:source]
    assert_nil Console.config.security_controller # base config object has no defaults
  end

  test 'Console.config.env handles value types' do
    expects_file_read(<<-FILE.strip_heredoc)
      BROKER_URL=foo
      ARRAY=[1, '2']
      SYMBOL=:foo
      HASH={'a' => 1}
      NUMBER=1234
      STRING="1234"
      STRING_2='1234'
    FILE
    Console.configure('file')
    assert_nil Console.config.env(:TEST)
    assert_equal 'foo', Console.config.env(:TEST, 'foo')
    assert_equal 'foo', Console.config.env(:BROKER_URL)
    assert_equal :foo, Console.config.env(:SYMBOL)
    assert_equal([1, '2'], Console.config.env(:ARRAY))
    assert_equal({'a' => 1}, Console.config.env(:HASH))
    assert_equal 1234, Console.config.env(:NUMBER)
    assert_equal '1234', Console.config.env(:STRING)
    assert_equal '1234', Console.config.env(:STRING_2)
  end

  test 'Console.config.env checks boolean types' do
    expects_file_read(<<-FILE.strip_heredoc)
      BROKER_URL=foo
      BOOL1 = true
      BOOL2 = false
      BAD_BOOL1 = 'true'
      BAD_BOOL2 = 'false'
    FILE

    Console.configure('file')
    assert_equal true, Console.config.env_bool(:BOOL1)
    assert_equal false, Console.config.env_bool(:BOOL2)

    assert_raise(Console::InvalidConfiguration) { Console.config.env_bool(:MISSING) }
    assert_raise(Console::InvalidConfiguration) { Console.config.env_bool(:MISSING, 'true') }
    assert_raise(Console::InvalidConfiguration) { Console.config.env_bool(:MISSING, 'false') }
    
    assert_equal true, Console.config.env_bool(:MISSING, true)
    assert_equal false, Console.config.env_bool(:MISSING, false)

    assert_raise(Console::InvalidConfiguration) { Console.config.env_bool(:BAD_BOOL1) }
    assert_raise(Console::InvalidConfiguration) { Console.config.env_bool(:BAD_BOOL1, true) }
    assert_raise(Console::InvalidConfiguration) { Console.config.env_bool(:BAD_BOOL2) }
    assert_raise(Console::InvalidConfiguration) { Console.config.env_bool(:BAD_BOOL2, false) }
  end

  test 'Console.configure default succeeds' do
    Console.configure(File.expand_path('../../../conf/console.conf.example', __FILE__))
  end

  test 'Console.configure raises IO errors' do
    IO.expects(:read).with(File.expand_path('file')).raises(Errno::ENOENT)
    assert_raise(Errno::ENOENT){ Console.configure('file') }
  end

  test 'Console.configure raises InvalidConfiguration' do
    expects_file_read(<<-FILE.strip_heredoc)
    FILE
    assert_raise(Console::InvalidConfiguration){ Console.configure('file') }
  end

  test 'Console.configure sets security_controller from basic' do
    expects_file_read(<<-FILE.strip_heredoc)
      BROKER_URL=foo
      CONSOLE_SECURITY=basic
    FILE
    Console.configure('file')
    assert_equal Console::Auth::Basic, Console.config.security_controller.constantize
  end

  test 'Console.configure sets security_controller from remote_user' do
    expects_file_read(<<-FILE.strip_heredoc)
      BROKER_URL=foo
      CONSOLE_SECURITY=remote_user
      REMOTE_USER_HEADER=X-Remote-User
      REMOTE_USER_NAME_HEADER=X-Remote-User-Name
      REMOTE_USER_COPY_HEADERS=X-Remote-User,Cookies
    FILE
    Console.configure('file')
    assert_equal Console::Auth::RemoteUser, Console.config.security_controller.constantize
    assert_equal ['X-Remote-User','Cookies'], Console.config.remote_user_copy_headers
    assert_equal 'X-Remote-User', Console.config.remote_user_header
    assert_equal 'X-Remote-User-Name', Console.config.remote_user_name_header
  end

  test 'Console.configure sets security_controller to arbitrary' do
    expects_file_read(<<-FILE.strip_heredoc)
      BROKER_URL=foo
      CONSOLE_SECURITY=Console::Auth::None
    FILE
    Console.configure('file')
    assert_equal Console::Auth::None, Console.config.security_controller.constantize
  end

  test 'Console.config.api sets api :external' do
    old_env = ENV.delete('CONSOLE_CONFIG_FILE')
    begin
      expects_file_read(<<-FILE.strip_heredoc, '~/.openshift/console.conf')
        BROKER_URL=foo
        BROKER_API_SOURCE=ignored
        BROKER_API_USER=bob
        BROKER_API_SYMBOL=:foo
        BROKER_API_TIMEOUT=0
        BROKER_API_SSL_OPTIONS={:verify_mode => OpenSSL::SSL::VERIFY_NONE}
        BROKER_PROXY_URL=proxy
        CONSOLE_SECURITY=Console::Auth::None
      FILE
      (config = Console::Configuration.new).api = :external
      assert_equal 'foo', config.api[:url]
      assert_equal 'proxy', config.api[:proxy]
      assert_equal 'bob', config.api[:user]
      assert_equal :foo, config.api[:symbol]
      assert_equal 0, config.api[:timeout]
      assert_equal '~/.openshift/console.conf', config.api[:source]
      assert_equal({'verify_mode' => OpenSSL::SSL::VERIFY_NONE}, config.api[:ssl_options])
      assert_equal OpenSSL::SSL::VERIFY_NONE, config.api[:ssl_options][:verify_mode]
      assert_nil config.security_controller # is ignored
    ensure
      ENV['CONSOLE_CONFIG_FILE'] = old_env
    end
  end

  test 'Console.config.api accepts :local' do
    (config = Console::Configuration.new).api = :local
    assert_equal 'https://localhost/broker/rest', config.api[:url]
    assert_equal :local, config.api[:source]
    assert_nil config.security_controller # is ignored
  end

  test 'Console.config.api accepts valid object' do
    (config = Console::Configuration.new).api = {:url => 'foo', :user => 'bob'}
    assert_equal 'foo', config.api[:url]
    assert_equal 'bob', config.api[:user]
    assert_equal 'object in config', config.api[:source]
    assert_nil config.security_controller # is ignored
  end

  test 'Console.config.api raises on invalid object' do
    assert_raise(Console::InvalidConfiguration){ Console::Configuration.new.api = {:url => nil, :user => 'bob'} }
  end

  test 'Console.config.api raises on unrecognized option' do
    assert_raise(Console::InvalidConfiguration){ Console::Configuration.new.api = nil }
  end
end

