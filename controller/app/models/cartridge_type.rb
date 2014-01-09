class CartridgeType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :priority, type: DateTime
  has_many :successors, class_name: 'CartridgeType', inverse_of: :predecessor
  belongs_to :predecessor, class_name: 'CartridgeType', inverse_of: :successors, autobuild: false

  field :manifest_url, type: String
  field :text, type: String

  field :base_name, type: String
  field :version, type: String
  field :cartridge_vendor, type: String

  field :categories, type: Array, default: []
  # Provides an indexable search field for both names and requires
  field :provides, type: Array, default: []

  field :cartridge_version, type: String
  field :obsolete, type: Boolean
  field :display_name, type: String
  field :description, type: String

  attr_accessible :name, :manifest_url, :text,
                  :base_name, :version, :cartridge_vendor,
                  :categories, :provides,
                  :cartridge_version, :obsolete, :display_name, :description

  # Attributes that are loaded from the descriptor
  delegate :license, :license_url, :website, :help_topics,
           :properties, :usage_rates,
           to: :cartridge

  index({ name: 1, priority: -1 }, { sparse: true })
  index({ provides: 1 })

  create_indexes

  validates :name, presence: true
  validates :base_name, presence: true
  validates :version, presence: true
  validates :cartridge_vendor, presence: true
  validates :provides, presence: true
  validate :name_matches_components

  scope :active, lambda{ ne(priority: nil) }

  def self.provides(name)
    self.in(provides: name)
  end

  def self.update_from(sources, url=nil)
    missing = sources.inject({}){ |h, m| h[m.global_identifier] = m; h }
    updated = []
    self.in(name: missing.keys).each do |type|
      latest = missing.delete(type.name) or next
      old = type
      old.attributes = cartridge_attributes(latest, url)
      if old.changed?
        type = new(old.attributes)
        type.predecessor = old
        updated << type
      end
    end
    missing.each_pair do |name, latest|
      updated << new(cartridge_attributes(latest, url))
    end
    updated
  end

  def self.cartridge_attributes(source, url=nil, text=nil)
    c =
      case source
      when OpenShift::Runtime::Manifest
        text ||= source.manifest.to_json
        OpenShift::Cartridge.new.from_descriptor(source.manifest)
      when OpenShift::Cartridge
        text ||= source.to_descriptor.to_json
        source
      when Hash
        text ||= source.to_json
        OpenShift::Cartridge.new.from_descriptor(source)
      else
        raise "Invalid source"
      end
    {
      name: c.name,
      manifest_url: url,
      base_name: c.original_name,
      version: c.version,
      cartridge_vendor: c.cartridge_vendor,
      display_name: c.display_name,
      description: c.description,
      obsolete: c.is_obsolete?,
      provides: (c.features + c.names).uniq,
      categories: c.categories,
      text: text,
    }
  end

  def activate
    self.priority = Time.now
    if self.save
      self.class.where(name: name, :priority.lt => self.priority).set(:priority, nil)
      if latest = self.class.where(name: name, :priority.ne => nil).only(:_id, :priority).first
        if latest._id == self._id
          true
        else
          self.errors.add(:base, "Another cartridge version #{latest._id} was activated at #{latest.priority}.")
          false
        end
      else
        self.errors.add(:base, "Another person has disabled this cartridge.")
        false
      end
    end
  end

  def cartridge
    @cartridge ||= begin
      cart = OpenShift::Cartridge.new.from_descriptor(JSON.parse(text))
      cart.manifest_url = manifest_url
      cart
    end
  end

  #
  # Methods for compatibility with OpenShift::Cartridge
  #
  include OpenShift::CartridgeCategories
  include OpenShift::CartridgeNaming
  include OpenShift::CartridgeAspects

  alias_method :original_name, :base_name

  alias_method :is_obsolete?, :obsolete?
  alias_method :global_identifier, :name

  delegate :components_in_profile, to: :cartridge

  def has_feature?(feature)
    provides.include?(feature)
  end

  def ===(other)
    return true if other == self
    if other.is_a?(String)
      if cartridge_vendor == "redhat"
        name == other || full_name == other
      else
        name == other
      end
    end
  end

  def usage_rates
    @usage_rates || []
  end

  protected
    def name_matches_components
      errors.add(:name, "The specified name '#{name}' does not match the attributes '#{cartridge_vendor}', '#{original_name}', and '#{version}'.}") unless global_identifier == name
    end
end
