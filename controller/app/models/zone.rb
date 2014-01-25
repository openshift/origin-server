class Zone
  include Mongoid::Document
  include Mongoid::Timestamps
  include ModelHelper

  embedded_in :region, class_name: Region.name
  field :name, type: String

  validates :name, :presence => true

  ZONE_NAME_REGEX = /\A[A-Za-z0-9]*\z/
  def self.check_name!(name)
    if name.blank? or name !~ ZONE_NAME_REGEX
      raise Mongoid::Errors::DocumentNotFound.new(Zone, nil, [name])
    end
    name
  end

  def has_servers?
    found = false
    District.only(:server_identities).each do |district|
      if district.server_identities.where(zone_id: self._id).exists?
        found = true
        break
      end
    end
    found
  end
end
