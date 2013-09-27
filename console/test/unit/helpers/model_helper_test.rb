require File.expand_path('../../../test_helper', __FILE__)


class Console::ModelHelperTest < ActionView::TestCase

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

  def test_web_cartridge_scale_title
    assert /maximum amount/i =~ web_cartridge_scale_title(stub(:current_scale => 2, :scales_from => 1, :scales_to => 2))
    assert /minimum amount/i =~ web_cartridge_scale_title(stub(:current_scale => 1, :scales_from => 1, :scales_to => 2))
    assert /multiple copies/i =~ web_cartridge_scale_title(stub(:current_scale => 2, :scales_from => 1, :scales_to => 3))
  end

  def test_scale_from_options
    assert_equal({
        :as => :select, 
        :collection => [['1',1],['2',2],['3',3]],
        :include_blank => false,
      }, 
      scale_from_options(stub(:supported_scales_from => 1, :supported_scales_to => -1), 3))
    assert_equal({
        :as => :string
      }, 
      scale_from_options(stub(:supported_scales_from => 1, :supported_scales_to => -1), 6, 5))
  end

  def test_scale_to_options
    assert_equal({
        :as => :select, 
        :collection => [['1',1],['2',2],['3',3],['All available', -1]],
        :include_blank => false,
      },
      scale_to_options(stub(:supported_scales_from => 1, :supported_scales_to => -1), 3))
    assert_equal({
        :as => :string,
        :hint => 'Use -1 to scale to your current account limits',
      },
      scale_to_options(stub(:supported_scales_from => 1, :supported_scales_to => -1), 6, 5))
  end

  Tagged = Struct.new(:tags)

  def test_in_groups_by_tag
    t1 = Tagged.new([:ruby, :php])
    t2 = Tagged.new([:ruby])

    groups, others = in_groups_by_tag([t1], [:ruby])
    assert_equal [t1], others
    assert groups.empty?

    groups, others = in_groups_by_tag([t1, t2], [:ruby])
    assert_equal [[:ruby, [t1, t2]]], groups
    assert others.empty?
  end
end
