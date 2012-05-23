require File.expand_path('../../../test_helper', __FILE__)


class ModelHelperTest < ActionView::TestCase

  def test_gear_group_states
    assert_equal 'Started', gear_group_states([:started])
    assert_equal 'Stopped', gear_group_states([:stopped])
    assert_equal 'Unknown', gear_group_states([:unknown])
    assert_equal 'Foo', gear_group_states([:foo])
    assert_equal 'Unknown', gear_group_states([:unknown, :unknown])
    assert_equal '0/2 started', gear_group_states([:unknown, :stopped])
    assert_equal '1/2 started', gear_group_states([:started, :stopped])
    assert_equal 'Started', gear_group_states([:started, :started])
  end
end
