class KeyTypeValidator < ActiveModel::Validator
  def validate(record)
    unless SshKey::VALID_SSH_KEY_TYPES.include? record.type
      record.errors.add(:type, "Invalid key type.  Valid types are #{SshKey::VALID_SSH_KEY_TYPES.join(", ")}")
    end
  end
end