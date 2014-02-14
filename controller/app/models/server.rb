class Server
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :district, class_name: District.name
  field :name, type: String
  field :active, type: Boolean, default: true
  field :unresponsive, type: Boolean, default: false
  field :region_name, type: String
  field :zone_name, type: String
  field :region_id, type: Moped::BSON::ObjectId 
  field :zone_id, type: Moped::BSON::ObjectId

  validates :name, :presence => true
  validates :zone_name, :presence => true, :if => :validate_zone_name?
  validates :zone_id, :presence => true, :if => :validate_zone_id?
  validates :region_id, :presence => true, :if => :validate_region_id?

  def validate_zone_name?
    (region_name.present? ? true : false)
  end

  def validate_zone_id?
    (zone_name.present? ? true : false)
  end

  def validate_region_id?
    (region_name.present? ? true : false)
  end
end
