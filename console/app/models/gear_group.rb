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
    counts = {}
    groups.each do |g|
      g.cartridges.each do |c|
        counts[c.name] = (counts[c.name] || 0) + (g.scales? ? 0 : g.gears.length) # the carts on the haproxy gear group do not count
      end
    end

    groups.each do |g|
      g.gears.each{ |gear| gear.gear_profile = g.gear_profile }
      g.cartridges.each{ |c| c.runs_on(g.gears) }
    end

    scaling, groups = groups.partition(&:scales?)
    scaling.each do |scaled_group|
      scaling_carts = scaled_group.send(:scales_cartridges)
      will_scale = groups.select{ |g| (g.cartridge_names & scaling_carts).present? }
      will_scale.each{ |g| g.send(:scales_with, scaling_carts, scaled_group, counts) }

      if group = scaled_group.send(:without_scaling)
        groups << group
      elsif will_scale.first
        will_scale.first.gears.concat(scaled_group.gears)
      else
        scaled_group.send(:scales_with, scaling_carts, scaled_group, counts)
        groups << scaled_group
      end
    end

    web, groups = groups.partition{ |g| g.exposes? {|c| c.tags.include?(:web_framework)} }
    data, groups = groups.partition{ |g| g.exposes? {|c| c.tags.include?(:database)} }

    tiers.concat(web).concat(data).concat(groups)
    tiers.delete_if {|t| t.send(:move_features, tiers[0]) }
    tiers.each{ |t| t.cartridges.sort! }

    if tiers[0]
      cart = tiers[0].cartridges[0]
      cart.git_url = application.git_url
      cart.ssh_url = application.ssh_url
      cart.ssh_string = application.ssh_string
    end
    tiers
  end

  protected
    #
    # Move the scaling cart to embedded metadata, mark other cartridges as scaled
    #
    def scales_with(carts, from, counts)
      @scales = true
      cartridges.select{ |c| carts.include?(c.name) && c.tags.include?(:web_framework) }.each{ |c| c.scales_with(SCALING_CART_NAME, from, counts[c.name]) }
    end
    #
    # Return true if the group is now empty
    #
    def move_features(to)
      cartridges.delete_if do |c|
        if c.tags.include?(:ci_builder) and not c.tags.include?(:web_framework)
          to.cartridges.select{ |d| d.tags.include?(:web_framework) }.each{ |d| d.builds_with(c, self) }.present?
        end
      end
      if self != to && cartridges.empty?
        to.gears.concat(gears)
        gears.clear
      end
    end

    # create a gear group without scaling or the scaled cartridge (assumes that this cart IS scaled)
    def without_scaling
      other = self.clone
      other.cartridges.reject!{ |c| c.tags.include?(:web_framework) or c.tags.include?(:scales) }
      other if other.cartridges.present?
    end

    # FIXME assumes that the gear group with haproxy has only cartridges that it scales (in a
    # deactivated state).  This assumption should be replaced when the scales_with attribute
    # is introduced
    def scales_cartridges
      cartridges.map(&:name).uniq.reject!{ |n| n == SCALING_CART_NAME } || []
    end

  private
    SCALING_CART_NAME = 'haproxy-1.4' #FIXME don't hardcode

end
