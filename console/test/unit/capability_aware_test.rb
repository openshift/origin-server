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

  test 'user capabilities handles defaults' do
    User.expects(:find).returns(User.new(:capabilities => {}))
    assert cap = obj.user_capabilities
    assert_equal session_defaults(nil,0,[], nil), obj.session[:caps]
    assert_equal Capabilities::UnlimitedGears, cap.max_gears
    assert_equal 0, cap.consumed_gears
    assert cap.gears_free?
    assert_equal Capabilities::UnlimitedGears, cap.gears_free
    assert_equal [], cap.gear_sizes
  end

  test 'user capabilities handles API 1.1 settings' do
    User.expects(:find).returns(User.new(:max_gears => 3, :consumed_gears => 1, :plan_id => 'foo', :capabilities => {:gear_sizes => ['small','medium']}))
    assert cap = obj.user_capabilities
    assert_equal session_defaults(3,1,[:small,:medium], 'foo'), obj.session[:caps]
    assert_equal 3, cap.max_gears
    assert_equal 1, cap.consumed_gears
    assert_equal 'foo', cap.plan_id
    assert cap.gears_free?
    assert_equal 2, cap.gears_free
    assert_equal [:small, :medium], cap.gear_sizes
  end

  test 'user capabilities deserializes session' do
    obj.session[:caps] = [nil, 0, ['small']]
    assert cap = obj.user_capabilities
    assert_equal Capabilities::UnlimitedGears, cap.max_gears
    assert_equal 0, cap.consumed_gears
    assert_equal [:small], cap.gear_sizes
  end
end
