class NamespaceValidator < ActiveModel::EachValidator
  NAMESPACE_MAX_LENGTH = 16 unless defined? NAMESPACE_MAX_LENGTH
  NAMESPACE_MIN_LENGTH = 1 unless defined? NAMESPACE_MIN_LENGTH

  def validate_each(record, attribute, val)
    if !val
      record.errors.add(attribute, {:message => "Namespace is required and cannot be blank.", :exit_code => 106})
    elsif val and val.length < NAMESPACE_MIN_LENGTH
      record.errors.add(attribute, {:message => "Namespace is too short.  Minimum length is #{NAMESPACE_MIN_LENGTH} characters.", :exit_code => 106})
    elsif val and val.length > NAMESPACE_MAX_LENGTH
      record.errors.add(attribute, {:message => "Namespace is too long.  Maximum length is #{NAMESPACE_MAX_LENGTH} characters.", :exit_code => 106})
    elsif val and !(val =~ /\A[A-Za-z0-9]+\z/)
      record.errors.add(attribute, {:message => "Invalid namespace. Namespace must only contain alphanumeric characters.", :exit_code => 106})
    elsif val and OpenShift::ApplicationContainerProxy.blacklisted? val
      record.errors.add(attribute, {:message => "Namespace is not allowed.  Please choose another.", :exit_code => 106})
    end
  end
end
