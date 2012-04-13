class ActiveSupport::TestCase

  def setup_domain
    @domain = Domain.new :name => "#{uuid}", :as => @user
    unless @domain.save
      puts @domain.errors.inspect
      fail 'Unable to create the initial domain, test cannot be run'
    end
    @domain
  end

  def cleanup_user?
    not @with_unique_user
  end

  # some unit tests or test environments may want to preserve domains
  # created for unique users
  alias_method :cleanup_domain?, :cleanup_user?

  def cleanup_domain
    if cleanup_domain? 
      @domain.destroy_recursive if @domain
    end
  end

  #
  # Create a domain and user that are shared by all tests in the test suite, 
  # and is only destroyed at the very end of the suite.  If you do not clean
  # up after creating applications you will hit the application limit for
  # this user.
  #
  def with_domain
    with_configured_user
    once :domain do
      domain = Domain.first :as => @user
      domain.destroy_recursive if domain
      @@domain = setup_domain
      if cleanup_domain?
        lambda do
          begin
            @@domain.destroy_recursive
          rescue ActiveResource::ResourceNotFound
          end
        end
      end
    end
    @domain = @@domain
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
end
