class BlacklistedValidator < ActiveModel::Validator
  def validate(record)
    if record.is_a? Application
      val = record.name
      if val and OpenShift::ApplicationContainerProxy.blacklisted? val
        record.errors.add(:name, "Name is not allowed.  Please choose another.")
      end
    elsif record.is_a? Domain
      val = record.namespace
      if val and OpenShift::ApplicationContainerProxy.blacklisted? val
        record.errors.add(:namespace, "Namespace is not allowed.  Please choose another.")
      end
    end
  end
end