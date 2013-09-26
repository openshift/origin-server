class GearGroup < RestApi::Base
  singular_resource

  schema do
    string :name, :gear_profile
    integer :scales_from, :scales_to
    integer :supported_scales_from, :supported_scales_to
    integer :base_gear_storage, :additional_gear_storage
  end
  custom_id :name

  belongs_to :application

  has_many :gears
  has_many :cartridges

  def gears
    @attributes['gears'] ||= []
  end
  def cartridges
    @attributes['cartridges'] ||= []
  end

  def gear_profile
    (@attributes['gear_profile'] || :small).to_sym
  end

  def states
    gears.map{ |g| g.state }
  end

  def exposes
    @exposes ||= cartridges.inject({}) { |h, c| h[c.name] = c; h }
  end
  def exposes?(cart=nil, &block)
    if cart
      exposes.has_key? cart
    elsif block_given?
      cartridges.any? &block
    end
  end

  def cartridge_names
    exposes.keys
  end

  def scales?
    supported_scales_to != supported_scales_from
  end
  def builds?
    @builds
  end

  def supported_scales_from
    super || 1
  end

  def supported_scales_to
    super || -1
  end

  def ==(other)
    super && other.gears == gears && other.cartridges == cartridges
  end

  def merge_gears(others)
    Array(others).select{ |o| !(cartridges & o.cartridges).empty? }.each{ |o| gears.concat(o.gears) }
    gears.uniq!
    self
  end

  def self.infer(cartridges, application)
    groups = cartridges.group_by(&:grouping).map do |a|
      GearGroup.new({
        :cartridges => a[1].sort!,
        :gear_profile => a[1].first.gear_profile
      }, true)
    end
    groups.sort!{ |a,b| a.cartridges.first <=> b.cartridges.first }
    groups
  end
end