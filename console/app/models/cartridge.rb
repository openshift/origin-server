#
# The REST API model object representing a cartridge instance.
#
class Cartridge < RestApi::Base
  include Comparable

  schema do
    string :name, 'type'
  end
  custom_id :name

  attr_accessor :git_url, :ssh_url, :ssh_string
  attr_reader :gears

  belongs_to :application
  has_one :cartridge_type

  delegate :display_name, :tags, :priority, :to => :cartridge_type, :allow_nil => false

  def type
    @attributes[:type]
  end

  def type=(type)
    @attributes[:type]=type
  end

  def runs_on(new_gears)
    gears.concat(new_gears)
  end
  def gears
    @gears ||= []
  end
  def gear_count
    @gears.length
  end

  def scales
    @scales || ScaleRelation::Null
  end
  def scales?
    @scales.present?
  end
  def scales_with(cart, gear_group, times)
    @scales = ScaleRelation.new cart, gear_group.is_a?(String) ? gear_group : gear_group.name, times
  end

  def buildable?
    git_url.present? and tags.include? :web_framework
  end
  def builds
    @builds || BuildRelation::Null
  end
  def builds?
    @builds.present?
  end
  def builds_with(cart, gear_group)
    @builds = BuildRelation.new cart, gear_group.is_a?(String) ? gear_group : gear_group.name
  end

  def <=>(other)
    return 0 if name == other.name
    cartridge_type <=> other.cartridge_type
  end

  def cartridge_type
    @cartridge_type ||= CartridgeType.cached.find(name)
  end
end

class Cartridge::ScaleRelation
  attr_accessor :with, :on, :times

  def initialize(with, on, times)
    @with, @on, @times = with, on, times
  end

  Null = new(nil,nil,1)
end
class Cartridge::BuildRelation
  attr_accessor :with, :on

  def initialize(with, on)
    @with, @on = with, on
  end

  Null = new(nil,nil)
end
