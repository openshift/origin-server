class LoginValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add(:login, {:message => "Invalid characters found in login '#{record.login}' ", :exit_code => 107}) if record.login =~ /["\$\^<>\|%\/;:,\\\*=~]/
  end
end
