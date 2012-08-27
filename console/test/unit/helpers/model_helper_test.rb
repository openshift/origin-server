require File.expand_path('../../../test_helper', __FILE__)


class Console::ModelHelperTest < ActionView::TestCase

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

  def test_gear_group_count
    s = Gear.new(:gear_profile => :small)
    m = Gear.new(:gear_profile => :medium)
    l = Gear.new(:gear_profile => :large)
    t = Gear.new(:gear_profile => :tiny)
    assert_equal '1 small', gear_group_count([s])
    assert_equal '1 medium and 1 small', gear_group_count([s, m])
    assert_equal '1 large, 1 medium, and 1 small', gear_group_count([s, m, l])
    assert_equal '2 large', gear_group_count([l,l])
    assert_equal 'None', gear_group_count([])
  end

  def test_gear_group_count_title
    cart = stub(:gear_count => 1, :builds? => false, :scales? => false)
    assert /OpenShift runs/ =~ gear_group_count_title(cart, 0)
    assert /OpenShift runs/ =~ gear_group_count_title(cart, 1)
    assert /1 gear\s/ =~ gear_group_count_title(cart, 2)
    assert /expose the other cartridges\./ =~ gear_group_count_title(cart, 2)
    assert /2 gears\s/ =~ gear_group_count_title(cart, 3)
  end

  def test_gear_group_count_title_builds
    cart = stub(:gear_count => 1, :builds? => true, :scales? => false)
    assert /OpenShift runs/ =~ gear_group_count_title(cart, 0)
    assert /OpenShift runs/ =~ gear_group_count_title(cart, 1)
    assert /1 gear\s/ =~ gear_group_count_title(cart, 2)
    assert /handle builds\./ =~ gear_group_count_title(cart, 2)
    assert /2 gears\s/ =~ gear_group_count_title(cart, 3)
  end

  def test_gear_group_count_title_scales
    cart = stub(:gear_count => 1, :builds? => false, :scales? => true)
    assert /OpenShift runs/ =~ gear_group_count_title(cart, 0)
    assert /OpenShift runs/ =~ gear_group_count_title(cart, 1)
    assert /1 gear\s/ =~ gear_group_count_title(cart, 2)
    assert /\sscale\./ =~ gear_group_count_title(cart, 2)
    assert /2 gears\s/ =~ gear_group_count_title(cart, 3)
  end

  def test_gear_group_count_title_scales_and_builds
    cart = stub(:gear_count => 1, :builds? => true, :scales? => true)
    assert /OpenShift runs/ =~ gear_group_count_title(cart, 0)
    assert /OpenShift runs/ =~ gear_group_count_title(cart, 1)
    assert /1 gear\s/ =~ gear_group_count_title(cart, 2)
    assert /handle builds and scaling\./ =~ gear_group_count_title(cart, 2)
    assert /2 gears\s/ =~ gear_group_count_title(cart, 3)
  end
end
