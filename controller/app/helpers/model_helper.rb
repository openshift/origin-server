module ModelHelper

  def serializable_hash_with_timestamp
    unless self.persisted?
      if self.created_at.nil?
        self.set_created_at
      end
      if self.updated_at.nil? and self.able_to_set_updated_at?
        self.set_updated_at
      end
    end
    self._type = self.class.to_s unless self._type
    self.serializable_hash
  end
end
