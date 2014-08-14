require File.expand_path('../../../test_helper', __FILE__)


class Console::ModelHelperTest < ActionView::TestCase

  def test_assigned_region
    gear_groups = [
      GearGroup.new(
        :gears => [
          Gear.new(:region => 'west'),
          Gear.new(:region => 'west')
        ]
      ),
      GearGroup.new
    ]
    assert_equal 'west', assigned_region(gear_groups)
  end

  def test_assigned_region_when_gear_has_no_region
    gear_groups = [
      GearGroup.new(
        :gears => [Gear.new]
      )
    ]
    assert_nil assigned_region(gear_groups)
  end

  def test_assigned_region_when_gear_has_nil_region
    gear_groups = [
      GearGroup.new(
        :gears => [Gear.new(:region => nil)]
      )
    ]
    assert_nil assigned_region(gear_groups)
  end

  def test_assigned_region_when_gear_groups_empty
    assert_nil assigned_region([])
  end

  def test_assigned_region_when_gear_groups_nil
    assert_nil assigned_region(nil)
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
    t3 = Tagged.new([:ruby, :php, :java])

    # If only one type matches a given tag, the type should go under others.
    groups, others = in_groups_by_tag([t1], [:ruby])
    assert_equal [t1], others
    assert groups.empty?

    # If two types match a given tag, the types should be grouped together.
    groups, others = in_groups_by_tag([t1, t2], [:ruby])
    assert_equal [[:ruby, [t1, t2]]], groups
    assert others.empty?
  end

  def test_assigned_region_when_gear_groups_empty
    assert_nil assigned_region([])
  end

  def test_assigned_region_when_gear_groups_nil
    assert_nil assigned_region(nil)
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
    t3 = Tagged.new([:ruby, :php, :java])

    # If only one type matches a given tag, the type should go under others.
    groups, others = in_groups_by_tag([t1], [:ruby])
    assert_equal [t1], others
    assert groups.empty?

    # If two types match a given tag, the types should be grouped together.
    groups, others = in_groups_by_tag([t1, t2], [:ruby])
    assert_equal [[:ruby, [t1, t2]]], groups
    assert others.empty?

    # If a type matches more than one tag, but it is the only type that matches
    # the first matching tag, and multiple types match a subsequent tag, then
    # the type should be grouped under the first such subsequent tag.
    groups, others = in_groups_by_tag([t1, t3], [:java, :php, :ruby])
    assert_equal [[:php, [t1, t3]]], groups
    assert others.empty?
  end
end

describe Console::ModelHelper do
  include Console::ModelHelper

  before do
    @regions = [
      Region.new(:id => '123', :name => 'region 1', :default=>false),
      Region.new(:id => '456', :name => 'region 2', :default=>true),
      Region.new(:id => '789', :name => 'region 3', :default=>false)
    ]
    @default = 'region 2'
  end

  describe '#allow_region_selection' do

    it { allow_region_selection?(nil).must_equal false }
    it { allow_region_selection?([]).must_equal false }

    it 'should be false if all are nil' do 
      allow_region_selection?(@regions).must_equal false
    end

    it 'should be true if atleast one is true' do 
      @regions[1].allow_selection = true
      allow_region_selection?(@regions).must_equal true
    end

  end

  describe '#default_region' do

    it 'should return nil for an empty list' do
      default_region([]).must_be_nil
    end

    it 'should return nil for no defaults' do
      @regions.each {|r| r.default = false}
      default_region(@regions).must_be_nil
    end

    it 'should return the name for the default region' do
      default_region(@regions).must_equal(@default)
    end

  end

end
