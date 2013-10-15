class KeyTypeValidator < ActiveModel::Validator
  def validate(record)
    unless SshKey.get_valid_ssh_key_types.include? record.type
      record.errors.add(:type, "Invalid key type.  Valid types are #{SshKey.get_valid_ssh_key_types.join(", ")}")
    end
  end
end