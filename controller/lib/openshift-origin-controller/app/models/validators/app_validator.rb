class AppValidator < ActiveModel::Validator
  APP_NAME_MAX_LENGTH = 32 unless defined? APP_NAME_MAX_LENGTH
  APP_NAME_MIN_LENGTH = 1 unless defined? APP_NAME_MIN_LENGTH
  def validate(record)
    attributes.each do |attribute|
      value = record.read_attribute_for_validation(attribute)
      if attribute == "name"
        validate_name(record, attribute, valuse)
      end
    end
  end

  def validate_name(record, attribute, val)
    if val.nil?
      record.errors.add(attribute, {:message => "Name is required and cannot be blank.", :exit_code => 105})
    end
    if !(val =~ /\A[A-Za-z0-9]+\z/)
      record.errors.add(attribute, {:message => "Invalid name. Name must only contain alphanumeric characters.", :exit_code => 105})
    end
    if val and val.length > APP_NAME_MAX_LENGTH
      record.errors.add(attribute, {:message => "Name is too long.  Maximum length is #{APP_NAME_MAX_LENGTH} characters.", :exit_code => 105})
    end
    if val and val.length < APP_NAME_MIN_LENGTH
      record.errors.add(attribute, {:message => "Name is too short.  Minimum length is #{APP_NAME_MIN_LENGTH} characters.", :exit_code => 105})
    end
    if val and OpenShift::ApplicationContainerProxy.blacklisted? val
      record.errors.add(attribute, {:message => "Name is not allowed.  Please choose another.", :exit_code => 105})
    end
  end
end