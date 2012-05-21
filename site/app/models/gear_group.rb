class GearGroup < RestApi::Base
  schema do
    string :name, :gear_profile
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
    @scales or exposes? SCALING_CART_NAME
  end
  def builds?
    @builds
  end

  def ==(other)
    super && other.gears == gears && other.cartridges == cartridges
  end

  def merge(other)
    [:gears, :cartridges].each { |s| self.send(s).concat(other.send(s)).uniq! }
    self
  end

  def self.simplify(groups, application)
    tiers = []

    # can be simplified when the group exposes which cart it scales
    group = groups.find(&:scales?)
    if group
      scaled_group = group.clone
      scaling_carts = group.send(:scales_cartridges)
      unscaled, scaled = groups.partition{ |g| (g.cartridge_names & scaling_carts).empty? }
      scaled.each{ |g| scaled_group.merge(g) unless g.equal?(group) }
      scaled_group.send(:merge_scaling_cart, scaling_carts, scaled_group)

      tiers << scaled_group
      groups = unscaled
    end

    web, groups = groups.partition{ |g| g.exposes? {|c| c.categories.include?(:web)} }
    data, groups = groups.partition{ |g| g.exposes? {|c| c.categories.include?(:web)} }

    tiers.concat(web).concat(data).concat(groups)
    tiers.each {|t| t.cartridges.sort! }

    tiers.delete_if {|t| t.send(:move_features, tiers[0]) }

    tiers[0].cartridges[0].git_url = application.git_url if tiers[0]

    tiers
  end

  protected
    #
    # Move the scaling cart to embedded metadata, mark other cartridges as scaled
    #
    def merge_scaling_cart(on, from)
      @scales ||= ! cartridges.reject!{ |c| c.name == SCALING_CART_NAME }.nil?
      cartridges.select{ |c| on.include?(c.name) && c.categories.include?(:web) }.each{ |c| c.scales_with(SCALING_CART_NAME, from) } if @scales
    end
    #
    # Return true if the group is now empty
    #
    def move_features(to)
      cartridges.delete_if do |c|
        if c.categories.include?(:builds)
          to.cartridges.select{ |d| d.categories.include?(:web) }.each{ |d| d.builds_with(c, self) }.present?
        end
      end
      if self != to && cartridges.empty?
        to.gears.concat(gears)
        gears.clear
      end
    end
    def scales_cartridges
      cartridges.map(&:name).uniq.reject!{ |n| n == SCALING_CART_NAME } || []
    end

  private
    SCALING_CART_NAME = 'haproxy-1.4' #FIXME don't hardcode

end
