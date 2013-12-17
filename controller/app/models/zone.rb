class Zone
  include Mongoid::Document
  include Mongoid::Timestamps
  include ModelHelper

  embedded_in :region, class_name: Region.name
  field :name, type: String

  validates :name, :presence => true

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
