require File.expand_path('../../test_helper', __FILE__)

class CapabilityAwareTest < ActiveSupport::TestCase

  def obj_class
    Class.new(Object) do
      def self.around_filter(*args); end
      attr_accessor :current_user
      def session
        @session ||= {}
      end

      include CapabilityAware
    end
  end
  def obj
    @test_obj ||= obj_class.new
  end

  def session_defaults(*args)
    args
  end

  test 'user capabilities handle wrapped hashes' do
    assert caps = Console.config.capabilities_model_class.from(Class.new(SimpleDelegator).new(:max_gears => 2, :consumed_gears => 0))
    assert_equal 2, caps.max_gears
    assert_equal 0, caps.consumed_gears
  end

  test 'user capabilities handles defaults' do
    User.expects(:find).returns(User.new(:capabilities => {}))
    assert cap = obj.user_capabilities
    assert_equal session_defaults(-1, 1, nil, 0, [], nil, 0, false), obj.session[:caps]
    assert_equal 1, cap.max_domains
    assert_equal Capabilities::UnlimitedGears, cap.max_gears
    assert_equal 0, cap.consumed_gears
    assert cap.gears_free?
    assert_equal Capabilities::UnlimitedGears, cap.gears_free
    assert_equal [], cap.gear_sizes
  end

  test 'user capabilities handles API 1.1 settings' do
    User.expects(:find).returns(User.new(:max_gears => 3, :consumed_gears => 1, :max_domains => 2, :plan_id => 'foo', :capabilities => {:gear_sizes => ['small','medium']}))
    assert cap = obj.user_capabilities
    assert_equal session_defaults(-1, 2, 3, 1, [:small,:medium], 'foo', 0, false), obj.session[:caps]
    assert_equal 2, cap.max_domains
    assert_equal 3, cap.max_gears
    assert_equal 1, cap.consumed_gears
    assert_equal 'foo', cap.plan_id
    assert cap.gears_free?
    assert_equal 2, cap.gears_free
    assert_equal [:small, :medium], cap.gear_sizes
  end

  test 'user capabilities deserializes session' do
    obj.session[:caps] = [-1, 10, nil, 0, ['small']]
    assert cap = obj.user_capabilities
    assert_equal 10, cap.max_domains
    assert_equal Capabilities::UnlimitedGears, cap.max_gears
    assert_equal 0, cap.consumed_gears
    assert_equal [:small], cap.gear_sizes
  end

  test 'user capabilities ignores invalid versions' do
    User.expects(:find).returns(User.new(:capabilities => {:gear_sizes => ['small','medium']}))
    obj.session[:caps] = [-2, nil, nil, 0, ['small']]
    assert cap = obj.user_capabilities
    assert_equal [:small, :medium], cap.gear_sizes
  end
end
