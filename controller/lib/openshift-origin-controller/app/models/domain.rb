require 'validators/namespace_validator'
class Domain < OpenShift::UserModel
  include ActiveModel::Validations
  attr_accessor :uuid, :namespace, :user
  primary_key :uuid
  exclude_attributes :user
  validates :namespace, :namespace => true
  def initialize(namespace=nil, user=nil)
    self.user = user
    self.namespace = namespace
    self.uuid = OpenShift::Model.gen_uuid
  end
  def save
    resultIO = ResultIO.new
    created = false
    if not persisted?
      resultIO.append(create())
      created = true
    else
      resultIO.append(update())
    end

    begin
      super(self.user.login)
    rescue
      delete_dns if created
      raise
    end
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
  
  def self.get(user, id)
    user.domains.each do |domain|
      return domain if domain.namespace == id
    end if user.domains
    return nil
  end

  def delete_dns
    dns_service = OpenShift::DnsService.instance
    begin
      dns_service.deregister_namespace(self.namespace)
      dns_service.publish
    ensure
      dns_service.close
    end
  end

  def delete
    Rails.logger.debug "Deleting domain #{self.namespace} uuid #{self.uuid}"
    resultIO = ResultIO.new
    delete_dns
    super(user.login)
    Rails.logger.debug "notifying the domain observer of domain delete"
    notify_observers(:after_domain_destroy) 
    Rails.logger.debug "done notifying the domain observer"
    resultIO
  end
   
  def self.namespace_available?(namespace)
    Rails.logger.debug "Checking to see if namesspace #{namespace} is available"
    dns_service = OpenShift::DnsService.instance
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
    dns_service = OpenShift::DnsService.instance

    begin 
      raise OpenShift::UserException.new("A namespace with name '#{self.namespace}' already exists", 103) unless dns_service.namespace_available?(self.namespace)
      dns_service.register_namespace(self.namespace)
      dns_service.deregister_namespace(old_namespace)
      cloud_user = self.user
      prepare_failures = []
      
      cloud_user.applications.each do |app|
        if app.domain.uuid == self.uuid
          Rails.logger.debug "Updating namespace to #{self.namespace} for app: #{app.name}"
          result = app.prepare_namespace_update(dns_service, self.namespace, old_namespace)
          prepare_failures.push(app.name) unless result[:success]
          result_io.append result[:result_io]
        end
      end if cloud_user.applications
 
      complete_exception = nil
      begin
        cloud_user.applications.each do |app|
          if app.domain.uuid == self.uuid
            app.complete_namespace_update(self.namespace, old_namespace)
          end
        end if cloud_user.applications and prepare_failures.empty?
      rescue Exception => e
        complete_exception = e
        Rails.logger.debug e.message
        Rails.logger.debug e.backtrace
      end

      dns_exception = nil
      begin
        dns_service.publish if prepare_failures.empty? and !complete_exception
      rescue Exception => e
        dns_exception = e
        Rails.logger.debug e.message
        Rails.logger.debug e.backtrace
      end

      # Rollback incase of failures
      if !prepare_failures.empty? or complete_exception or dns_exception
        undo_prepare_failures = []
        undo_prepare_err_msg = ""
        cloud_user.applications.each do |app|
          if app.domain.uuid == self.uuid
            Rails.logger.debug "Undo namespace update to #{old_namespace} for app: #{app.name}"
            result = app.prepare_namespace_update(dns_service, old_namespace, self.namespace)
            undo_prepare_failures.push(app.name) unless result[:success]
            result_io.append result[:result_io]
          end
        end if cloud_user.applications
        undo_prepare_err_msg = "Undo namespace update failed: #{undo_prepare_failures.pretty_inspect.chomp}." unless undo_prepare_failures.empty?
 
        undo_complete_err_msg = "" 
        begin
          cloud_user.applications.each do |app|
            if app.domain.uuid == self.uuid
              app.complete_namespace_update(old_namespace, self.namespace)
            end
          end if cloud_user.applications
        rescue Exception => e
          undo_complete_err_msg = "Undo namespace update failed: #{e.message}."
          Rails.logger.debug e.message
          Rails.logger.debug e.backtrace
        end

        err_msg = "Error updating namespace: "
        err_code = 143
        if dns_exception
          err_msg += dns_exception.message
          err_code = dns_exception.code if dns_exception.respond_to?('code')
        elsif complete_exception
          err_msg += complete_exception.message
          err_code = complete_exception.code if complete_exception.respond_to?('code')
        else # prepare failures
          err_msg += prepare_failures.pretty_inspect.chomp
        end
        err_msg += undo_prepare_err_msg + undo_complete_err_msg
        raise OpenShift::NodeException.new(err_msg + " If the problem persists please contact support.", err_code)
      end
      Rails.logger.debug "Notifying domain observer of domain update"
      notify_observers(:after_domain_update)
    ensure
      dns_service.close
    end
    result_io
  end

  def create
    Rails.logger.debug "Creating domain #{self.uuid} with namespace #{self.namespace} for user #{self.user.login}"
    resultIO = ResultIO.new
    dns_service = OpenShift::DnsService.instance
    begin
      raise OpenShift::UserException.new("A namespace with name '#{self.namespace}' already exists", 103) unless dns_service.namespace_available?(self.namespace)
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
          Rails.logger.debug "Attempting to remove namespace '#{@namespace}' after failure to add user '#{self.user.login}'"
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
