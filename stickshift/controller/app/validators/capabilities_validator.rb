class CapabilitiesValidator < ActiveModel::Validator
  def validate(record)
    if record.capabilities.nil?
      record.errors.add(:capabilities, {:message => "User capabilities is nil", :exit_code => -1})
    else
      ["subaccounts", "gear_sizes", "max_gears"].each do |key| 
        record.errors.add(:capabilities, {:message => "Missing #{key} capability", :exit_code => -1}) if record.capabilities[key].nil?
      end
    end
  end
end
