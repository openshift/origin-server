class KeyValidator < ActiveModel::Validator
    KEY_NAME_MAX_LENGTH = 256
    KEY_NAME_MIN_LENGTH = 1
  def validate(record)
    if !record.content
      record.errors.add("content", {:message => "Key content is required and cannot be blank.", :exit_code => 108})
    end
    if record.content and !(record.content=~ /\A[A-Za-z0-9\+\/=]+\z/)
      record.errors.add("content", {:message => "Invalid key content: '#{record.content}'.", :exit_code => 108})
    end
    if !record.name
      record.errors.add("name", {:message => "Key name is required and cannot be blank.", :exit_code => 117})
    end
    if record.name and  !(record.name =~ /\A[A-Za-z0-9]+\z/)
      record.errors.add("name", {:message => "Invalid key name: '#{record.name}'", :exit_code => 117})
    end
    if record.name and record.name.length > KEY_NAME_MAX_LENGTH
      record.errors.add("name", {:message => "Key name '#{record.name}' is too long.  Maximum length is #{KEY_NAME_MAX_LENGTH} characters.", :exit_code => 117})
    end
    if record.name and record.name.length < KEY_NAME_MIN_LENGTH
      record.errors.add("name", {:message => "Key name '#{record.name}' is too short.  Minimum length is #{KEY_NAME_MIN_LENGTH} characters.", :exit_code => 117})
    end
    if !record.type
      record.errors.add("type", {:message => "Key type is required and cannot be blank.", :exit_code => 116})
    end
    if record.type and !(record.type =~ /^(ssh-rsa|ssh-dss)$/)
      record.errors.add("type", {:message => "Invalid key type: '#{record.type}'.  Valid types are ssh-rsa or ssh-dss.", :exit_code => 116})
    end
  end
end