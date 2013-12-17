class CartridgeType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :manifest_url, type: String
  embeds_many :streams, class_name: CartridgeStream.name

  # Seconds to token expiration
  field :expires_in, :type => Integer
  field :revoked_at, :type => DateTime

  index({ name: 1 }, { unique: true })
  index({ 'streams.provides' => 1 })

  attr_accessible :name, :manifest_url, :streams

  create_indexes

  validates :name, uniqueness: true
  validates :streams, presence: true, length: {minimum: 1}

  def self.from_manifest(manifests, url=nil)
    new(
      name: manifests[0].name,
      manifest_url: url,
      streams: manifests.map{ |m| CartridgeStream.from_manifest(m) }
    )
  end

  def update_from_manifest(manifests)
    if names = manifests.select{ |m| m.name != name }.presence
      raise OpenShift::UserException, "The new cartridge version names '#{names.uniq.join(', ')}' does not match the current name #{name}"
    end
    _assigning do
      new_versions = manifests.map(&:version).uniq
      streams.each do |s|
        s.obsolete = true unless new_versions.include?(s.version)
      end
      manifests.each do |m|
        streams.select{ |s| s.version == m.version }.each do |s|
          s.manifest_attributes(m)
        end.present? or streams << CartridgeStream.from_manifest(m)
      end
    end
  end
end
