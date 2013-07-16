module OpenShift
  # Represents a generic distributed lock object
  # @!attribute [r] type
  #   @return [String] Lock type/name, eg: sync_usage, billing_plan
  # @!attribute [r] owner_id
  #   @return [String] Lock owner, eg: node ip address 
  # @!attribute [r] allow_multiple_access
  #   @return [Boolean] allows owner to acquire same lock type multiple times
  class DistributedLock
    include Mongoid::Document
    include Mongoid::Timestamps

    field :type, type: String
    field :owner_id, type: String
    field :allow_multiple_access, type: Boolean, default: false

    validates :type, presence: true
    validates :owner_id, presence: true

    index({:type => 1}, {:unique => true})
    create_indexes

    def self.obtain_lock(type, owner_id, allow_multiple_access=false)
      Rails.logger.debug "obtain_distributed_lock, type: #{type}, owner_id: #{owner_id}"
      filter = {:type => type}
      if allow_multiple_access
        filter["$or"] = [{:owner_id => owner_id}, {:owner_id => nil}, {:owner_id.exists => false}]
      else
        filter["$or"] = [{:owner_id => nil}, {:owner_id.exists => false}]
      end
      dlock_obj = nil
      begin
        dlock_obj = where(filter).find_and_modify({"$set" => {owner_id: owner_id, type: type}}, 
                                                  {:upsert => true, :new => true})
      rescue Moped::Errors::OperationFailure
      end
      if dlock_obj && dlock_obj.owner_id == owner_id
        return true
      else
        return false
      end
    end

    def self.release_lock(type, owner_id=nil)
      Rails.logger.debug "release_distributed_lock, type: #{type}, owner_id: #{owner_id}"
      filter = { "type" => type }
      filter["owner_id"] = owner_id if owner_id
      where(filter).destroy
    end
  end
end
