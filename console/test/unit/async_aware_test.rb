require File.expand_path('../../test_helper', __FILE__)

class AsyncAwareTest < ActiveSupport::TestCase

  def obj
    @test_obj ||= Class.new(Object) do
      include AsyncAware
      def logger
        Logger.new
      end
    end.new
  end

  class A < StandardError; end
  class B < StandardError; end
  class C < StandardError; end

  test "runs in order" do
    obj.async{ 'a' }
    obj.async{ 'b' }
    assert_equal ['a','b'], obj.join
    assert_equal 1, Thread.list.size

    assert_raise(NoMethodError){ obj.join }
  end
  test "returns in consistent order" do
    obj.async{ sleep(0.01); 'a' }
    obj.async{ 'b' }
    assert_equal ['a','b'], obj.join
  end
  test "join returns results" do
    obj.async{ sleep(0.01); raise A }
    obj.async{ sleep(0.02); raise B }
    obj.async{ 'c' }
    arr = obj.join
    assert arr[0].is_a? A
    assert arr[1].is_a? B
    assert_equal 'c', arr[2]
  end
  test "join! raises the first exception" do
    obj.async{ sleep(0.01); raise A }
    obj.async{ raise B }
    assert_raise(A){ result obj.join! }
    assert_equal 1, Thread.list.size
  end
  test "join on thread expiration returns timeout" do
    obj.async{ sleep(1) }
    assert_raise(AsyncAware::ThreadTimedOut){ obj.join!(0.01) }
  end
  test "Thread timeout has message" do
    ex = AsyncAware::ThreadTimedOut.new(Thread.current, 13045)
    assert /13045/ =~ ex.to_s
    assert ex.to_s.include? Thread.current.inspect
  end
end
