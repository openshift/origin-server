require 'validators/namespace_validator'
class Domain < StickShift::UserModel
  include ActiveModel::Validations
  attr_accessor :uuid, :namespace, :user
  primary_key :uuid
  exclude_attributes :user
  validates :namespace, :namespace => true
  def initialize(namespace=nil, user=nil)
    self.user = user
    self.namespace = namespace
    self.uuid = StickShift::Model.gen_uuid
  end
  def save
    resultIO = ResultIO.new
    if not persisted?
      resultIO.append(create())
    else
      resultIO.append(update())
    end
    super(self.user.login)
    resultIO
  end  
  def hasAccess?(user)
    #TODO 
    #if user.domains.include? self.uuid
      return true
    #end
    #return false
  end
  
  def hasFullAccess?(user)
    #TODO
    #if self.user.login == user.login
      return true
    #end
    #return false
  end
  
  def self.find(user, id)
    domain = super(user.login, id)
    domain.user = user if domain
    return nil unless domain
    domain
  end
  
  def self.find_all(user, namespace=nil)
    domains = super(user.login) 
    unless namespace
      user.domains = domains
      return domains
    else
      filtered_domains = nil
      domains.each do |domain|
        if domain.namespace == namespace
          filtered_domains.push(domain)
        end
      end
      return filtered_domains
    end    
  end
  
  def delete
    Rails.logger.debug "Deleting domain #{self.namespace} uuid #{self.uuid}"
    resultIO = ResultIO.new
    dns_service = StickShift::DnsService.instance
    begin
      dns_service.deregister_namespace(self.namespace)
      dns_service.publish
      Rails.logger.debug "notifying the domain observer of domain delete"
      notify_observers(:after_domain_destroy) 
      Rails.logger.debug "done notifying the domain observer"
    ensure
      dns_service.close
    end
    super(user.login)
    resultIO
  end
   
  def self.namespace_available?(namespace)
    Rails.logger.debug "Checking to see if namesspace #{namespace} is available"
    dns_service = StickShift::DnsService.instance
    return dns_service.namespace_available?(namespace)
  end
  def self.hash_to_obj(hash)
    domain = super(hash)
    domain
  end

  private

  def update
    result_io = ResultIO.new
    old_domain = Domain.find(self.user, self.uuid)
    old_namespace = old_domain.namespace
    Rails.logger.debug "Updating namespace for domain #{self.uuid} from #{old_namespace} to #{self.namespace}"
    dns_service = StickShift::DnsService.instance
    
    begin
      raise StickShift::UserException.new("A namespace with name '#{self.namespace}' already exists", 103) unless dns_service.namespace_available?(self.namespace)
      dns_service.register_namespace(self.namespace)
      dns_service.deregister_namespace(old_namespace)
      cloud_user = self.user
      update_namespace_failures = []
      
      cloud_user.applications.each do |app|
        Rails.logger.debug "App's domain #{app.domain.uuid}"
        if app.domain.uuid == self.uuid
          Rails.logger.debug "Updating namespace to #{self.namespace} for app: #{app.name}"
          result = app.prepare_namespace_update(dns_service, self.namespace, old_namespace)
          update_namespace_failures.push(app.name) unless result[:success]
          result_io.append result[:result_io]
        end
      end
      
      cloud_user.applications.each do |app|
        if app.domain.uuid == self.uuid
          app.complete_namespace_update(self.namespace, old_namespace)
        end
      end

      if update_namespace_failures.empty?
        dns_service.publish
      else
        raise StickShift::NodeException.new("Error updating apps: #{update_namespace_failures.pretty_inspect.chomp}.  Updates will not be completed until all apps can be updated successfully.  If the problem persists please contact support.",143)
      end

      Rails.logger.debug "notifying domain observer of domain update"
      notify_observers(:after_domain_update) 
      #Rails.logger.debug "done notifying the domain observers"
    rescue StickShift::SSException => e
      Rails.logger.error "Exception caught updating namespace: #{e.message}"
      Rails.logger.debug e.backtrace
      raise
    rescue Exception => e
      Rails.logger.error "Exception caught updating namespace: #{e.message}"
      Rails.logger.debug e.backtrace
      raise StickShift::SSException.new("An error occurred updating the namespace.  If the problem persists please contact support.",1)
    ensure
      dns_service.close
    end
    result_io
  end

  def create
    Rails.logger.debug "Creating domain #{self.uuid} with namespace #{self.namespace} for user #{self.user.login}"
    resultIO = ResultIO.new
    dns_service = StickShift::DnsService.instance
    begin
      raise StickShift::UserException.new("A namespace with name '#{self.namespace}' already exists", 103) unless dns_service.namespace_available?(self.namespace)
      begin
        Rails.logger.debug "Attempting to add namespace '#{@namespace}'"
        dns_service.register_namespace(@namespace)
        dns_service.publish
        Rails.logger.debug "notifying the domain observer of domain create"
        notify_observers(:after_domain_create)
        Rails.logger.debug "done notifying the domain observer"
      rescue Exception => e
        Rails.logger.debug e
        begin
          Rails.logger.debug "Attempting to remove namespace '#{@namespace}' after failure to add user '#{@login}'"
          dns_service.deregister_namespace(@namespace)
          dns_service.publish
        ensure
          raise
        end
      end
    ensure
      dns_service.close
    end
    resultIO
  end
end
