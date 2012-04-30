class LegacyRequest < StickShift::Model
  attr_accessor :namespace, :rhlogin, :ssh, :app_uuid, :app_name, :node_profile, :debug, :alter, :delete, :cartridge, :api, :cart_type, :action, :server_alias, :api, :key_name, :key_type
  attr_reader   :invalid_keys
  
  APP_NAME_MAX_LENGTH = 32
  NAMESPACE_MAX_LENGTH = 16

  def initialize
    @invalid_keys = []
  end
  
  validates_each :invalid_keys do |record, attribute, val|
    val.each do |key|
      record.errors.add :base, {:message => "Unknown json key found: #{key}", :exit_code => 1}
    end
  end
  
  validates_each :rhlogin do |record, attribute, val|
    if val =~ /["\$\^<>\|%\/;:,\\\*=~]/
      record.errors.add attribute, {:message => "Invalid rhlogin: #{val}", :exit_code => 107}
    end
  end

  validates_each :key_name, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A[A-Za-z0-9]+\z/)
      record.errors.add attribute, {:message => "Invalid key name: #{val}", :exit_code => 117}
    end
  end
  
  validates_each :key_type, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /^(ssh-rsa|ssh-dss)$/)
      record.errors.add attribute, {:message => "Invalid key type: #{val}", :exit_code => 116}
    end
  end

  validates_each :namespace, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A[A-Za-z0-9]+\z/)
      record.errors.add attribute, {:message => "Invalid namespace: #{val}", :exit_code => 106}
    end
    if val and val.length > NAMESPACE_MAX_LENGTH
      record.errors.add attribute, {:message => "The namespace you entered (#{val}) is not available for use.  Please choose another one.", :exit_code => 106}
    end
  end
  
  validates_each :app_name, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A[A-Za-z0-9]+\z/)
      record.errors.add attribute, {:message => "Invalid #{attribute} specified: #{val}", :exit_code => 105}
    end
    if val and val.length > APP_NAME_MAX_LENGTH
      record.errors.add attribute, {:message => "The supplied application name '#{val}' is not allowed", :exit_code => 105}
    end
  end
  
  validates_each :ssh, :allow_nil =>true do |record, attribute, val|
    unless (val =~ /\A[A-Za-z0-9\+\/=]+\z/)
      record.errors.add attribute, {:message => "Invalid ssh key: #{val}", :exit_code => 108}
    end
  end

  validates_each :app_uuid, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A[a-f0-9]+\z/)
      record.errors.add attribute, {:message => "Invalid application uuid: #{val}", :exit_code => 1}
    end
  end
  
  validates_each :node_profile, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A(jumbo|exlarge|large|micro|small|medium)\z/)
      record.errors.add attribute, {:message => "Invalid Profile: #{val}.  Must be: (jumbo|exlarge|large|micro|medium|small)", :exit_code => 1}
    end
  end
  
  validates_each :debug, :alter, :delete, :allow_nil =>true do |record, attribute, val|
    if val != true && val != false && !(val =~ /\A(true|false)\z/)
      record.errors.add attribute, {:message => "Invalid value for #{attribute} specified: #{val}", :exit_code => 1}
    end
  end
  
  validates_each :cartridge, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A[\w\-\.]+\z/)
      record.errors.add attribute, {:message => "Invalid cartridge specified: #{val}", :exit_code => 1}
    end
  end
  
  validates_each :api, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A\d+\.\d+\.\d+\z/)
      record.errors.add attribute, {:message => "Invalid API value specified: #{val}", :exit_code => 112}
    end
  end
  
  validates_each :cart_type, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A(standalone|embedded)\z/)
      record.errors.add attribute, {:message => "Invalid cart_type specified: #{val}", :exit_code => 109}
    end
  end
  
  validates_each :action, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A[\w\-\.]+\z/)
      record.errors.add attribute, {:message => "Invalid action specified: #{val}", :exit_code => 111}
    end
  end

  validates_each :server_alias, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A[\w\-\.]+\z/) or (val =~ /#{Rails.configuration.ss[:domain_suffix]}$/)
      record.errors.add attribute, {:message => "Invalid ServerAlias specified: #{val}", :exit_code => 105}
    end
  end
  
  def alter
    @alter == "true" || @alter == true
  end
  
  def debug
    @debug == "true" || @debug == true
  end
  
  def delete
    @delete == "true" || @delete == true
  end

  def attributes=(hash)
    hash.each do |key,value|
      begin
        self.send("#{key}=",value)
      rescue NoMethodError => e
        @invalid_keys.push key
      end
    end
  end
end
