class ActiveSupport::TestCase

  def uuid
    @ts ||= new_uuid
  end
  def new_uuid
    "#{Time.now.to_i}#{gen_small_uuid[0,6]}"
  end

  def set_domain(domain)
    @domain = domain
  end

  def setup_domain
    domain = Domain.new :name => "#{uuid}", :as => @user
    begin
      domain.save!
    rescue Domain::AlreadyExists, Domain::UserAlreadyHasDomain
      domain.errors.clear
    rescue => e
      puts "Domain create failed: #{e.response.errors.inspect}" rescue nil
      raise
    end
    set_domain(domain)
  end
  def find_or_create_domain
    set_domain(Domain.find(:one, :as => @user))
  rescue
    setup_domain
  end

  def cleanup_user?
    not @with_unique_user
  end

  def new_named_user(name)
    new_user(:login => name, :password => 'foo')
  end

  def with_gear_size_user
    set_user(new_named_user('user_with_multiple_gear_sizes@test.com'))
    @controller.stubs(:current_user).returns(set_user(new_named_user('user_with_multiple_gear_sizes@test.com')))
  end

  # some unit tests or test environments may want to preserve domains
  # created for unique users
  alias_method :cleanup_domain?, :cleanup_user?

  def cleanup_domain
    if cleanup_domain? 
      @domain.destroy_recursive if @domain
    end
  end

  def with_unique_domain
    with_unique_user # FIXME: test for non-unique
    setup_domain
  end

  def delete_keys
    Key.find(:all, :as => @user).map(&:destroy)
  end

  def allow_duplicate_domains
    Domain.any_instance.expects(:check_duplicate_domain).at_least(0).returns(false)
  end

  def assert_attr_equal(o1, o2)
    unless o1 == o2
      assert o1, "#{o1} is not equal to #{o2}"
      assert o2, "#{o1} is not equal to #{o2}"
      if o1.is_a? Array and o2.is_a? Array
        assert o1.length == o2.length, "Array 1 length #{o1.length} is not array 2 length #{o2.length}"
        o1.each_with_index { |o,i| assert_attr_equal(o, o2[i]) }
      else
        assert_equal o1.attributes, o2.attributes, "Attributes do not match"
      end
    end
  end

  def setup_from_app(app)
    set_domain Domain.new({:id => app.domain_id, :as => app.as}, true)
    set_user app.as
    app
  end

  def self.api_cache
    @@cache ||= {}
  end

  def api_fetch(name, &block)
    varname = "@#{name}_cached"
    instance_variable_get(varname) || begin
      created = if cached = self.class.api_cache[name]
          block.call(cached) || cached
        else
          self.class.api_cache[name] = block.call(nil)
        end
      instance_variable_set(varname, created)
    end
  end

  def use_domain(symbol=nil, &block)
    api_fetch(symbol) do |cached|
      if cached
        set_domain cached
        set_user cached.as
        cached
      else
        if block_given?
          set_domain(yield block)
        else
          with_unique_domain
        end
      end
    end
  end

  #
  # Create or retrieve a domain and user.  Does not guarantee that the domain is
  # empty.  If other tests are running in parallel altering the domain may result
  # in errors.
  #
  def with_domain
    use_domain(:any)
  end

  def use_app(symbol, &block)
    api_fetch(symbol) do |cached|
      if cached
        setup_from_app(cached)
      else
        app = yield block if block_given?
        app ||= Application.new :name => uuid
        if app.as
          set_user(app.as)
        else
          with_unique_user
          app.as = @user
        end
        find_or_create_domain
        @domain.expects(:destroy).never
        begin
          app = @domain.find_application(app.name)
        rescue
          app.domain = @domain
          app.save!
        end
        app
      end
    end
  end

  def with_app
    use_app(:readable_app) { Application.new({:name => "normal", :cartridge => 'ruby-1.8', :as => new_named_user('user_with_normal_app')}) }
  end

  def with_scalable_app
    use_app(:scalable_app) { Application.new({:name => "scaled", :cartridge => 'ruby-1.8', :scale => true, :as => new_named_user('user_with_scaled_app')}) }
  end

  def mock_body_for(&block)
    req = ActiveResource::HttpMock.requests.find &block
    assert req, "No mock request was found for this block"
    body = req.body
    body = ActiveSupport::JSON.decode(req.body) if req.headers['Content-Type'].include?('application/json')
    body
  end

  def with_medium_gear_app_form
    { :name => uuid,
      :application_type => 'php-5.3',
      :gear_profile => 'medium',
      :domain_name => 'MEDIUMGEAR'
    }
  end

  def with_scalable_app_form
    { :name => uuid,
      :application_type => 'php-5.3',
      :scale => 'true',
      :domain_name => 'MEDIUMGEAR'
    }
  end

  def auth_headers
   h = {}
   h['Cookie'] = "rh_sso=#{@user.ticket}" if @user.ticket
   h['Authorization'] = ActionController::HttpAuthentication::Basic.encode_credentials(@user.login, @user.password) if @user.login
   h
  end

  def json_header(is_post=false)
    anonymous_json_header(is_post).merge!(auth_headers)
  end

  def anonymous_json_header(is_post=false)
    {(is_post ? 'Content-Type' : 'Accept') => 'application/json', 'User-Agent' => Console.config.api[:user_agent]}
  end

end
