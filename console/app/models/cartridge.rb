#
# The REST API model object representing a cartridge instance.
#
class Cartridge < RestApi::Base
  include Comparable

  singular_resource

  #use_patch_on_update

  schema do
    string :name, 'type', :url
    integer :supported_scales_from, :supported_scales_to
    integer :scales_from, :scales_to, :current_scale
    string :scales_with
    string :gear_profile
    integer :base_gear_storage, :additional_gear_storage
    string :gear_size
  end
  custom_id :name

  attr_accessor :git_url, :ssh_url, :ssh_string
  attr_reader :gears

  belongs_to :application
  has_one    :cartridge_type
  has_many   :collocated_with, :class_name => String
  has_many   :properties, :class_name => as_indifferent_hash
  has_one    :help_topics, :class_name => as_indifferent_hash
  has_one    :links, :class_name => as_indifferent_hash

  delegate :display_name, :tags, :priority, :database?, :web_framework?, :builder?, :jenkins_client?, :haproxy_balancer?, :to => :cartridge_type, :allow_nil => false

  def url
    CartridgeType.normalize_url(super)
  end

  def custom?
    url.present?
  end

  def collocated_with
    @attributes[:collocated_with] ||= []
  end

  def supported_scales_from
    super || 1
  end
  def supported_scales_to
    super || 1
  end

  def additional_gear_storage
    (super || 0).to_i
  end

  def base_gear_storage
    (super || 1).to_i
  end

  def total_storage
    base_gear_storage + additional_gear_storage
  end

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

  # deprecated
  def scales
    @scales || ScaleRelation::Null
  end

  def scales?
    @scales.present? || supported_scales_from != supported_scales_to
  end

  def uses_gears?
    !(scales_from == 0 && scales_to == 0)
  end

  # deprecated with args
  def scales_with(*args)
    args.length == 0 ? super : begin
      @scales = ScaleRelation.new args[0], args[1].is_a?(String) ? args[1] : args[1].name, args[2]
    end
  end

  def scales_with_type
    return nil unless scales_with.present?
    @scales_with_type ||= (CartridgeType.cached.find(scales_with) rescue CartridgeType.new(:name => scales_with))
  end

  def has_scale_range?
    scales? && scales_from != scales_to
  end

  def will_scale_to(account_max=Float::INFINITY)
    effective_scales_to(effective_supported_scales_to(account_max))
  end

  def effective_supported_scales_to(max=Float::INFINITY)
    supported_scales_to == -1 ? max : [supported_scales_to, max].min
  end

  def effective_scales_to(max=Float::INFINITY)
    scales_to == -1 ? max : [scales_to, max].min
  end

  def can_scale_up?(max=Float::INFINITY)
    current_scale < will_scale_to(max)
  end

  def can_scale_down?
    current_scale > scales_from
  end

  #
  # The build attributes are used for view manipulation only
  #
  # deprecated
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

  def builds_with_type
    return nil unless builds?
    builds.with
  end

  def grouping
    @grouping ||= [name].concat(collocated_with).uniq.sort
  end

  def data(name, default=nil)
    if prop = (properties || []).find{ |p| p['type'] == 'cart_data' && p['name'] == name.to_s }
      [prop['value'].presence || default, prop['description']]
    end
  end

  def <=>(other)
    return 0 if name == other.name
    cartridge_type <=> other.cartridge_type
  end

  def cartridge_type
    @cartridge_type ||= (CartridgeType.cached.find(name) rescue CartridgeType.new(@attributes.slice('name', 'url', 'display_name', 'website', 'version', 'type', 'tags', 'license', 'license_url', 'help_topics')))
  end
end

class Cartridge::ScaleRelation
  attr_accessor :with, :on, :times

  def initialize(with, on, times)
    @with, @on, @times = with, on, times
  end

  Null = new(nil,nil,1)

  def blank?
    @with.blank?
  end
end

class Cartridge::BuildRelation
  attr_accessor :with, :on

  def initialize(with, on)
    @with, @on = with, on
  end

  Null = new(nil,nil)
end
