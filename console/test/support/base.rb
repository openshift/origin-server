
def inline_test(file)
  require "#{Console::Engine.root}/#{Pathname.new(file).relative_path_from(Rails.application.root)}"
end

class ActiveSupport::TestCase

  def self.isolate(&block)
    self.module_eval do
      include ActiveSupport::Testing::Isolation
      setup do
        yield block
      end
    end
  end

  def self.uses_http_mock(sym=:always)
    require 'active_resource/persistent_http_mock'
    self.module_eval do
      setup{ RestApi.stubs(:application_domain_suffix).returns('test.rhcloud.com') }
      setup{ ActiveResource::HttpMock.enabled = true } unless sym == :sometimes
      teardown do
        ActiveResource::HttpMock.reset!
        ActiveResource::HttpMock.enabled = false
      end
    end
  end
  def allow_http_mock
    ActiveResource::HttpMock.enabled = true
  end

  setup { $VERBOSE = nil }
  teardown { $VERBOSE = false }
  setup :cache_clear

  #
  # By default, cache is preserved across most tests
  #
  def cache_clear
    Rails.cache.clear if rand(15) == 0
  end
  #
  # Some test suites may force the cache to be cleared
  #
  def self.with_clean_cache
    define_method :cache_clear do
      Rails.cache.clear
    end
  end

  #
  # In any test case where css_select is valid, take a form object or selector
  # and extract the data from that form.  Yields a block and returns either
  # the return value of the block or an array of [method, action, form_values]
  #
  def extract_form(form, &block)
    if form.is_a?(String)
      selector = form
      assert (form = css_select(selector).first), "Could not find '#{selector}' in the response"
    end
    values = {}
    (css_select(form, 'input') + css_select(form, 'textarea')).each do |input|
      (values[input['name']] ||= []) << input['value'] if input['value']
    end
    css_select(form, 'select').each do |input|
      (values[input['name']] ||= []) << input['value'] if input['value']
    end
    values.each_pair{ |k,v| values[k] = v.first if v.length == 1 }
    r = [form['method'], form['action'], values]
    block_given? ? yield(r) : r
  end

  #
  # Extract a form from the most recent response and perform an HTTP
  # post.  Yields and returns the response object.
  #
  def submit_form(selector, params={}, &block)
    extract_form(selector) do |method, action, values|
      uri = URI(action)
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data(values.merge!(params))
      http = Net::HTTP.new(uri.host, uri.port)
      http.set_debug_output $stderr if ENV['HTTP_DEBUG']
      if http.use_ssl = (uri.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http.start{ |http| http.request(req) }
    end.tap do |res|
      yield res if block_given?
    end
  end

  def with_config(name, value, &block)
    old = Rails.configuration.send(:"#{name}")
    Rails.configuration.send(:"#{name}=", value)
    yield
  ensure
    Rails.configuration.send(:"#{name}=", old)
  end

  def with_rescue_from(&block)
    old = Rails.configuration.action_dispatch.show_exceptions
    Rails.configuration.action_dispatch.show_exceptions = true
    #@request.env['action_dispatch.show_exceptions'] = true
    yield
  ensure
    Rails.configuration.action_dispatch.show_exceptions = old
  end

  def expects_integrated
    flunk 'Test requires integrated Streamline authentication' unless Rails.configuration.integrated
  end

  def gen_small_uuid()
    %x[/usr/bin/uuidgen].gsub('-', '').strip
  end

  @@name = 0
  def unique_name_format
    'name%i'
  end
  def unique_name(format=nil)
    (format || unique_name_format) % self.class.next
  end
  def self.next
    @@name += 1
  end

  @@once = []
  def once(symbol, &block)
    unless @@once.include? symbol
      @@once << symbol
      exit_block = yield block
      at_exit{ exit_block.call } if exit_block.respond_to? :call
    end
  end

  def community_url
    Console.config.community_url
  end
  def community_base_url(path='')
    "#{community_url}#{path}"
  end
end

raise "Fixed in Rails 4" if Rails::VERSION::MAJOR > 3
class ActionDispatch::Integration::Session
  def script_name
    @script_name ||= @app.config.relative_url_root if @app.respond_to?(:config)
  end

  def url_options
    @url_options ||= default_url_options.dup.tap do |url_options|
      url_options.reverse_merge!(controller.url_options) if controller

      if @app.respond_to?(:routes) && @app.routes.respond_to?(:default_url_options)
        url_options.reverse_merge!(@app.routes.default_url_options)
      end

      url_options.reverse_merge!(:host => host, :protocol => https? ? "https" : "http", :script_name => script_name)
    end
  end
end
