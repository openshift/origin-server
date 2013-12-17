class CartridgeStream
  include Mongoid::Document
  embedded_in :cartridge_type

  field :text, type: String
  field :version, type: String
  field :categories, type: Array, default: []
  field :provides, type: Array, default: []

  field :obsolete, type: Boolean
  field :display_name, type: String
  field :description, type: String
  field :cartridge_version, type: String
  field :cartridge_vendor, type: String

  validates :version, uniqueness: true, presence: true

  attr_accessible :version, :cartridge_version, :display_name, :description, :obsolete, :cartridge_vendor, :provides, :categories, :text

  attr_accessor :license, :license_url, :website, :help_topics,
                :properties, :usage_rates
  delegate :manifest_url, to: :cartridge_type

  def self.provides(name)
    CartridgeType.in(:'streams.provides' => name).inject([]) do |arr, t|
      t.streams.each do |s|
        arr << s if s.provides.include?(name)
      end
      arr
    end
  end

  def self.from_manifest(m)
    raise "No support for cartridge Profiles" if m.manifest['Profiles']
    new(manifest_attributes(m))
  end

  def self.manifest_attributes(m)
    text = m.manifest.to_json # in case Cartridge mangles the descriptor...
    c = OpenShift::Cartridge.new.from_descriptor(m.manifest)
    {
      version: c.version,
      cartridge_version: m.cartridge_version,
      display_name: c.display_name,
      description: c.description,
      obsolete: c.is_obsolete?,
      provides: (c.features + c.names).uniq,
      cartridge_vendor: c.cartridge_vendor,
      categories: c.categories,
      text: text,
    }
  end

  def manifest_attributes=(m)
    self.attributes = self.class.manifest_attributes(m)
  end
  def manifest_attributes=(m)
    self.attributes = self.class.manifest_attributes(m)
  end

  def cartridge
    @cartridge ||= begin
      cart = OpenShift::Cartridge.new.from_descriptor(JSON.parse(text))
      cart.manifest_url = manifest_url
      cart
    end
  end

  # Cartridge API compatibility
  def name
    global_identifier
  end

  def original_name
    cartridge_type.name
  end

  def has_feature?(feature)
    provides.include?(feature)
  end

  alias_method :is_obsolete?, :obsolete?

  #
  # Name-Version or Vendor-Name-Version.  Identical to Manifest#global_identifier
  #
  def global_identifier
    if cartridge_vendor.blank? or cartridge_vendor == "redhat"
      "#{original_name}-#{version}"
    else
      "#{cartridge_vendor}-#{original_name}-#{version}"
    end
  end
end