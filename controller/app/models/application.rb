require 'matrix'

class Matrix
  def []=(i, j, x)
    @rows[i][j] = x
  end
end

# Class to represent an OpenShift Application
# @!attribute [r] name
#   @return [String] The name of the application
# @!attribute [rw] domain_requires
#   @return [Array[String]] Array of IDs of the applications that this application is dependent on.
#     If the parent application is destroyed, this application also needs to be destroyed.
# @!attribute [rw] group_overrides
#   @return [Array[Array[String]]] Array of Array of components that need to be co-located
# @!attribute [r] domain
#   @return [Domain] Domain that this application is part of.
# @!attribute [r] user_ids
#   @return [Array[Moped::BSON::ObjectId]] Array of IDs of users that have access to this application.
# @!attribute [r] aliases
#   @return [Array[String]] Array of DNS aliases registered with this application.
#     @see {Application#add_alias} and {Application#remove_alias}
# @!attribute [rw] component_start_order
#   @return [Array[String]] Normally start order computed based on order specified by each component's manifest. This attribute is used to overrides the start order.
# @!attribute [rw] component_stop_order
#   @return [Array[String]] Normally stop order computed based on order specified by each component's manifest. This attribute is used to overrides the stop order.
# @!attribute [r] connections
#   @return [Array[ConnectionInstance]] Array of connections between components of this application
# @!attribute [r] component_instances
#   @return [Array[ComponentInstance]] Array of components in this application
# @!attribute [r] group_instances
#   @return [Array[GroupInstance]] Array of gear groups in the application
# @!attribute [r] app_ssh_keys
#   @return [Array[ApplicationSshKey]] Array of auto-generated SSH keys used by components of the application to connect to other gears
class Application
  include Mongoid::Document
  include Mongoid::Timestamps
  include UtilHelper
  APP_NAME_MAX_LENGTH = 32
  MAX_SCALE = -1
  GEAR_SIZES = ["small", "medium"]

  field :name, type: String
  field :canonical_name, type: String
  field :uuid, type: String, default: ""
  field :domain_requires, type: Array, default: []
  field :group_overrides, type: Array, default: []
  embeds_many :pending_op_groups, class_name: PendingAppOpGroup.name

  belongs_to :domain
  field :user_ids, type: Array, default: []
  field :aliases, type: Array, default: []
  field :component_start_order, type: Array, default: []
  field :component_stop_order, type: Array, default: []
  field :component_configure_order, type: Array, default: []
  field :default_gear_size, type: String, default: "small"
  field :scalable, type: Boolean, default: false
  field :init_git_url, type: String, default: ""
  embeds_many :connections, class_name: ConnectionInstance.name
  embeds_many :component_instances, class_name: ComponentInstance.name
  embeds_many :group_instances, class_name: GroupInstance.name
  embeds_many :app_ssh_keys, class_name: ApplicationSshKey.name
  
  index({'group_instances.gears.uuid' => 1}, {:unique => true, :sparse => true})
  index({'domain_id' => 1})
  create_indexes

  attr_accessor :user_agent

  validates :name,
    presence: {message: "Application name is required and cannot be blank."},
    format:   {with: /\A[A-Za-z0-9]+\z/, message: "Invalid application name. Name must only contain alphanumeric characters."},
    length:   {maximum: APP_NAME_MAX_LENGTH, minimum: 1, message: "Application name must be a minimum of 1 and maximum of #{APP_NAME_MAX_LENGTH} characters."},
    blacklisted: {message: "Application name is not allowed.  Please choose another."}
  validate :extended_validator

  # Returns a map of field to error code for validation failures.
  def self.validation_map
    {name: 105}
  end

  before_destroy do |app|
    raise "Please call destroy_app to delete all gears before deleting this application" if num_gears > 0
  end

  # Observer hook for extending the validation of the application in an ActiveRecord::Observer
  # @see http://api.rubyonrails.org/classes/ActiveRecord/Observer.html
  def extended_validator
    notify_observers(:validate_application)
  end

  def self.create_app(application_name, features, domain, default_gear_size = GEAR_SIZES[0], scalable=false, result_io=ResultIO.new, group_overrides=[], init_git_url=nil, user_agent=nil)
    default_gear_size = GEAR_SIZES[0] unless default_gear_size
    app = Application.new(domain: domain, name: application_name, default_gear_size: default_gear_size, scalable: scalable, app_ssh_keys: [], pending_op_groups: [], init_git_url: init_git_url)
    app.user_agent = user_agent
    features << "web_proxy" if scalable
    if app.valid?
      begin
        add_feature_result = app.add_features(features, group_overrides, init_git_url)
        result_io.append add_feature_result
      rescue Exception => e
        app.delete
        raise e
      end
      app
    else
      app.delete
      raise OpenShift::ApplicationValidationException.new(app)
    end
    app
  end

  def self.find(user, app_name)
    user.domains.each { |d| d.applications.each { |a| return a if a.canonical_name == app_name.downcase } }
    return nil 
  end

  def self.find_by_gear_uuid(gear_uuid)
    # obj_id = Moped::BSON::ObjectId(gear_uuid)
    obj_id = gear_uuid.to_s
    app = Application.where("group_instances.gears.uuid" => obj_id).first
    return [nil, nil] if app.nil?
    gear = app.group_instances.map { |gi| gi.gears.select { |g| g.uuid== obj_id } }.flatten[0]
    return [app, gear]
  end

  # Initializes the application
  #
  # == Parameters:
  # features::
  #   List of runtime feature requirements. Each entry in the list can be a cartridge name or a feature supported by one of the profiles within the cartridge.
  #
  # domain::
  #   The Domain that this application is part of.
  #
  # name::
  #   The name of this application.
  def initialize(attrs = nil, options = nil)
    super
    self.uuid = self._id.to_s if self.uuid=="" or self.uuid.nil?
    self.app_ssh_keys = []
    self.pending_op_groups = []
    self.save
  end

  # Setter for application name - sets the name and the canonical_name
  def name=(app_name)
    self.canonical_name = app_name.downcase
    super
  end

  # Adds an additional namespace to the application. This function supports the first step of the update namespace workflow.
  #
  # == Parameters:
  # new_namespace::
  #   The new namespace to add to the application
  #
  # parent_op::
  #   The pending domain operation that this update is part of.
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progress of the operation.
  def update_namespace(old_namespace, new_namespace, parent_op=nil)
    Application.run_in_application_lock(self) do
      result_io = ResultIO.new
      op_group = PendingAppOpGroup.new(op_type: :update_namespace, args: {"old_namespace" => old_namespace, "new_namespace" => new_namespace}, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def complete_update_namespace(old_namespace, new_namespace, parent_op=nil)
    Application.run_in_application_lock(self) do
      result_io = ResultIO.new
      op_group = PendingAppOpGroup.new(op_type: :complete_update_namespace, args: {"old_namespace" => old_namespace, "new_namespace" => new_namespace}, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      self.save
      result_io
    end
  end

  # Removes an existing namespace to the application. This function supports the second step of the update namespace workflow.
  #
  # == Parameters:
  # old_namespace::
  #   The old namespace to remove from the application
  #
  # parent_op::
  #   The pending domain operation that this update is part of.
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progress of the operation.
  def remove_namespace(old_namespace, parent_op=nil)
    Application.run_in_application_lock(self) do
      result_io = ResultIO.new
      op_group = PendingAppOpGroup.new(op_type: :remove_namespace, args: {"old_namespace" => old_namespace}, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  # Adds the given ssh key to the application.
  #
  # == Parameters:
  # user_id::
  #   The ID of the user associated with the keys. If the user ID is nil, then the key is assumed to be a system generated key.
  # keys::
  #   Array of keys to add to the application.
  # parent_op::
  #   {PendingDomainOps} object used to track this operation at a domain level.
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progress of the operation.
  def add_ssh_keys(user_id, keys, parent_op)
    return if keys.empty?
    key_attrs = get_updated_ssh_keys(user_id, keys)
    Application.run_in_application_lock(self) do
      op_group = PendingAppOpGroup.new(op_type: :update_configuration,  args: {"add_keys_attrs" => key_attrs}, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  # Removes the given ssh key from the application. If multiple users share the same key, only the specified users key is removed
  # but application access will still be possible.
  #
  # == Parameters:
  # user_id::
  #   The ID of the user associated with the keys. Update to system keys is not supported.
  # keys_attrs::
  #   Array of keys attributes to remove from the application. The name of the key is used to match existing keys.
  # parent_op::
  #   {PendingDomainOps} object used to track this operation at a domain level.
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progress of the operation.
  def remove_ssh_keys(user_id, keys_attrs, parent_op=nil)
    return if keys_attrs.empty?
    key_attrs = get_updated_ssh_keys(user_id, keys_attrs)
    Application.run_in_application_lock(self) do
      op_group = PendingAppOpGroup.new(op_type: :update_configuration, args: {"remove_keys_attrs" => key_attrs}, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  def add_env_variables(vars, parent_op=nil)
    Application.run_in_application_lock(self) do
      op_group = PendingAppOpGroup.new(op_type: :update_configuration, args: {"add_env_vars" => vars}, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  def remove_env_variables(vars, parent_op=nil)
    Application.run_in_application_lock(self) do
      op_group = PendingAppOpGroup.new(op_type: :update_configuration, args: {"remove_env_vars" => vars}, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  # Returns the total number of gears currently used by this application
  def num_gears
    num = 0
    group_instances.each { |g| num += g.gears.count}
    num
  end
  
  def group_instances_with_scale
    # processed_group_overrides, cleaned_group_overrides = process_group_overrides(self.component_instances.map{|c| c.to_hash}, self.group_overrides)
    
    #map to current group_instances
    self.group_instances.map do |group_instance|
      override_spec = group_instance.get_group_override
      # override_spec = processed_group_overrides.select{ |go| go["components"] == group_instance.to_hash[:component_instances] }.first
      group_instance.min = override_spec["min_gears"]
      group_instance.max = override_spec["max_gears"]
      group_instance
    end
  end

  # Returns the feature requirements of the application
  #
  # == Parameters:
  # include_pending::
  #   Include the pending changes when calculating the list of features
  #
  # == Returns:
  #   List of features
  def requires(include_pending=false)
    features = component_instances.map {|ci| get_feature(ci.cartridge_name, ci.component_name)}

    if include_pending
      self.pending_op_groups.each do |op_group|
        case op_group.op_type
        when :add_features
          features += op_group[:args]["features"]
        when :remove_features
          features -= op_group[:args]["features"]
        end
      end
    end

    features || []
  end

  # Adds components to the application
  # @note {#run_jobs} must be called in order to perform the updates
  def add_features(features, group_overrides=[], init_git_url=nil)
    features.each do |feature_name|
      cart = CartridgeCache.find_cartridge(feature_name)

      # Validate that the features support scalable if necessary
      if self.scalable && !(cart.is_plugin? || cart.is_service?)
        raise OpenShift::UserException.new("#{feature_name} cannot be embedded in scalable app '#{name}'.", 108)  
      end
      
      # Validate that this feature either does not have the domain_scope category
      # or if it does, then no other application within the domain has this feature already
      if cart.is_domain_scoped?
        begin
          if Application.where(domain_id: self.domain._id, "component_instances.cartridge_name" => cart.name).count() > 0
            raise OpenShift::UserException.new("An application with #{feature_name} already exists within the domain. You can only have a single application with #{feature_name} within a domain.")
          end
        rescue Mongoid::Errors::DocumentNotFound
          #ignore
        end
      end
    end
    
    result_io = ResultIO.new
    Application.run_in_application_lock(self) do
      self.pending_op_groups.push PendingAppOpGroup.new(op_type: :add_features, args: {"features" => features, "group_overrides" => group_overrides, "init_git_url"=>init_git_url}, user_agent: self.user_agent)
      self.run_jobs(result_io)
    end
    domain.with(consistency: :strong).reload
    domain.run_jobs
    result_io
  end

  # Removes components from the application
  # set force to true if deleting application
  # @note {#run_jobs} must be called in order to perform the updates
  def remove_features(features, group_overrides=[], force=false)
    installed_features = self.requires
    
    result_io = ResultIO.new
    features.each do |feature|
      cart = CartridgeCache.find_cartridge(feature)
      raise OpenShift::UserException.new("Invalid feature: #{feature}", 109) unless cart
      Rails.logger.debug "Removing feature #{feature}"
      
      if !force
        raise OpenShift::UserException.new("'#{feature}' cannot be removed", 137) if (cart.is_web_proxy? and self.scalable) or cart.is_web_framework?
        raise OpenShift::UserException.new("'#{feature}' is not a feature of '#{self.name}'", 135) unless installed_features.include? feature
      end
      
      if cart.is_ci_server?
        self.domain.applications.each do |uapp|
          next if self.name == uapp.name
          uapp.requires.each do |feature_name|
            ucart = CartridgeCache.find_cartridge(feature_name)
            if ucart.is_ci_builder?
              Application.run_in_application_lock(uapp) do
                uapp.pending_op_groups.push PendingAppOpGroup.new(op_type: :remove_features, args: {"features" => [feature_name], "group_overrides" => uapp.group_overrides}, user_agent: uapp.user_agent)
                uapp.run_jobs(result_io)
              end
            end
          end
        end
      end
    end
    Application.run_in_application_lock(self) do
      self.pending_op_groups.push PendingAppOpGroup.new(op_type: :remove_features, args: {"features" => features, "group_overrides" => group_overrides}, user_agent: self.user_agent)
      self.run_jobs(result_io)
    end
    domain.with(consistency: :strong).reload
    domain.run_jobs
    result_io
  end

  # Destroys all gears on the application.
  # @note {#run_jobs} must be called in order to perform the updates
  def destroy_app
    self.domain.applications.each { |app|
      app.domain_requires.each { |app_id|
        if app_id==self._id
          # now we have to worry if apps have a circular dependency among them or not
          # assuming not for now or else stack overflow
          app.destroy_app
          break
        end
      }
    }
    self.remove_features(self.requires, [], true)
    Application.run_in_application_lock(self) do
      self.pending_op_groups.push PendingAppOpGroup.new(op_type: :delete_app, user_agent: self.user_agent)
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  # Updates the component grouping overrides of the application and create tasks to perform the update.
  # @note {#run_jobs} must be called in order to perform the updates
  #
  # == Parameters:
  # group_overrides::
  #   A list of component grouping overrides to use while creating gears
  def set_group_overrides(group_overrides)
    Application.run_in_application_lock(self) do    
      pending_op = PendingAppOpGroup.new(op_type: :add_features, args: {"features" => [], "group_overrides" => group_overrides}, created_at: Time.new, user_agent: self.user_agent)
      pending_op_groups.push pending_op
      self.save
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end
  
  def update_component_limits(component_instance, scale_from, scale_to, additional_filesystem_gb)
    if additional_filesystem_gb && additional_filesystem_gb != 0
      max_storage = self.domain.owner.capabilities['max_storage_per_gear']
      raise OpenShift::UserException.new("User is not allowed to change storage quota", 164) unless max_storage
      raise OpenShift::UserException.new("User can not exceed max storage quota per gear: #{max_storage} GB", 166) if additional_filesystem_gb > max_storage
    end
    Application.run_in_application_lock(self) do    
      pending_op = PendingAppOpGroup.new(op_type: :update_component_limits, args: {"comp_spec" => component_instance.to_hash, "min"=>scale_from, "max"=>scale_to, "additional_filesystem_gb"=>additional_filesystem_gb}, created_at: Time.new, user_agent: self.user_agent)
      pending_op_groups.push pending_op
      self.save
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end    
  end

  # Scales the group instance that runs this component
  #
  # == Parameters:
  # component::
  #   Component to scale
  #
  # scale_by::
  #   Number of gears to add (+ve) or remove (-ve)
  def scale_by(group_instance_id, scale_by)
    raise OpenShift::UserException.new("Application #{self.name} is not scalable") if !self.scalable
    
    ginst = group_instances_with_scale.select {|gi| gi._id == group_instance_id}.first
    raise OpenShift::UserException.new("Cannot scale below minimum gear requirements.", 168) if scale_by < 0 && ginst.gears.length <= ginst.min
    raise OpenShift::UserException.new("Cannot scale up beyond maximum gear limit in app #{self.name}.", 168) if scale_by > 0 && ginst.gears.length >= ginst.max and ginst.max > 0
    
    Application.run_in_application_lock(self) do
      self.pending_op_groups.push PendingAppOpGroup.new(op_type: :scale_by, args: {"group_instance_id" => group_instance_id, "scale_by" => scale_by}, user_agent: self.user_agent)
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  # Returns the fully qualified domain name where the application can be accessed
  def fqdn(domain=nil)
    domain = domain || self.domain
    "#{self.name}-#{domain.namespace}.#{Rails.configuration.openshift[:domain_suffix]}"
  end

  # Returns the ssh URL to access the gear hosting the web_proxy component
  def ssh_uri(domain=nil)
    self.group_instances.each do |group_instance|
      if group_instance.gears.where(app_dns: true).count > 0
        gear = group_instance.gears.find_by(app_dns: true)
        return "#{gear.uuid}@#{fqdn(domain)}"
      end
    end
    ""
  end

  # Retrieves the gear state for all gears within the application.
  #
  # == Returns:
  #  Hash of gear id to gear state mappings
  def get_gear_states
    Gear.get_gear_states(group_instances.map{|g| g.gears}.flatten)
  end

  def to_descriptor
    h = {
      "Name" => self.name,
      "Requires" => self.requires(true)
    }

    h["Start-Order"] = @start_order unless @start_order.nil? || @start_order.empty?
    h["Stop-Order"] = @stop_order unless @stop_order.nil? || @stop_order.empty?
    h["Group-Overrides"] = self.group_overrides unless self.group_overrides.empty?

    h
  end

  def start(feature=nil)
    result_io = ResultIO.new
    op_group = nil
    if feature.nil?
      op_group = PendingAppOpGroup.new(op_type: :start_app, user_agent: self.user_agent)
    else
      op_group = PendingAppOpGroup.new(op_type: :start_feature, args: {"feature" => feature}, user_agent: self.user_agent)
    end
    Application.run_in_application_lock(self) do
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def start_component(component_name, cartridge_name)
    Application.run_in_application_lock(self) do
      result_io = ResultIO.new
      op_group = PendingAppOpGroup.new(op_type: :start_component, args: {"comp_spec" => {"comp" => component_name, "cart" => cartridge_name}}, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def stop(feature=nil, force=false)
    Application.run_in_application_lock(self) do
      result_io = ResultIO.new
      op_group = nil
      if feature.nil?
        op_group = PendingAppOpGroup.new(op_type: :stop_app, user_agent: self.user_agent)
      else
        op_group = PendingAppOpGroup.new(op_type: :stop_feature, args: {"feature" => feature}, user_agent: self.user_agent)
      end
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def stop_component(component_name, cartridge_name, force=false)
    Application.run_in_application_lock(self) do
      result_io = ResultIO.new
      op_group = PendingAppOpGroup.new(op_type: :stop_component, args: {"comp_spec" => {"comp" => component_name, "cart" => cartridge_name}, "force" => force}, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def restart(feature=nil)
    Application.run_in_application_lock(self) do
      result_io = ResultIO.new
      op_group = nil
      if feature.nil?
        op_group = PendingAppOpGroup.new(op_type: :restart_app, user_agent: self.user_agent)
      else
        op_group = PendingAppOpGroup.new(op_type: :restart_feature, args: {"feature" => feature}, user_agent: self.user_agent)
      end
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def restart_component(component_name, cartridge_name)
    Application.run_in_application_lock(self) do
      result_io = ResultIO.new
      op_group = PendingAppOpGroup.new(op_type: :restart_component, args: {"comp_spec" => {"comp" => component_name, "cart" => cartridge_name}}, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def reload_config(feature=nil)
    Application.run_in_application_lock(self) do
      result_io = ResultIO.new
      op_group = nil
      if feature.nil?
        op_group = PendingAppOpGroup.new(op_type: :reload_app_config, user_agent: self.user_agent)
      else
        op_group = PendingAppOpGroup.new(op_type: :reload_feature_config, args: {"feature" => feature}, user_agent: self.user_agent)
      end
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      result_io
    end
  end
  
  def threaddump
    result_io = ResultIO.new
    component_instances.each do |component_instance|
      GroupInstance.run_on_gears(component_instance.group_instance.gears, result_io, false) do |gear, r|
        r.append gear.threaddump(component_instance.cartridge_name)
      end
    end
    result_io
  end

  def reload_component_config(component_name, cartridge_name)
    Application.run_in_application_lock(self) do
      op_group = PendingAppOpGroup.new(op_type: :reload_component_config, args: {"comp_spec" => {"comp" => component_name, "cart" => cartridge_name}}, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  def tidy
    Application.run_in_application_lock(self) do
      result_io = ResultIO.new
      op_group = PendingAppOpGroup.new(op_type: :tidy_app, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def show_port
    #todo
    raise "noimpl"
  end

  def remove_gear(gear_uuid)
    raise OpenShift::UserException.new("Application #{self.name} is not scalable") if !self.scalable or gear_uuid.nil?
    Application.run_in_application_lock(self) do
      self.pending_op_groups.push PendingAppOpGroup.new(op_type: :remove_gear, args: {"gear_id" => gear_uuid}, user_agent: self.user_agent)
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  def status(feature=nil)
    result_io = ResultIO.new
    component_instances = get_components_for_feature(feature)
    component_instances.each do |component_instance|
      GroupInstance.run_on_gears(component_instance.group_instance.gears, result_io, false) do |gear, r|
        r.append gear.status(component_instance)
      end
    end
    result_io
  end

  def component_status(component_instance)
    #if cartridge_name.nil?
    #  component_instance = self.component_instances.find(component_name: component_name)
    #else
    #  component_instance = self.component_instances.find(component_name: component_name, cartridge_name: cartridge_name)
    #end
    result_io = ResultIO.new
    status_messages = []
    GroupInstance.run_on_gears(component_instance.group_instance.gears, result_io, false) do |gear, r|
      gear_output = gear.status(component_instance)
      status_messages += [{"gear_id" => gear._id.to_s, "message" => gear_output.resultIO.string}] 
      r.append gear_output
    end
    status_messages
  end

  # Register a DNS alias for the application.
  #
  # == Parameters:
  # fqdn::
  #   Fully qualified domain name of the alias to associate with this application
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progress of the operation.
  #
  # == Raises:
  # OpenShift::UserException if the alias is already been associated with an application.
  def add_alias(fqdn)
    # Server aliases validate as DNS host names in accordance with RFC
    # 1123 and RFC 952.  Additionally, OpenShift does not allow an
    # Alias to be an IP address or a host in the service domain.
    # Since DNS is case insensitive, all names are downcased for
    # indexing/compares.
    server_alias = fqdn.downcase
    if !(server_alias =~ /\A[0-9a-zA-Z\-\.]+\z/) or
        (server_alias =~ /#{Rails.configuration.openshift[:domain_suffix]}$/) or
        (server_alias.length > 255 ) or
        (server_alias.length == 0 ) or
        (server_alias =~ /^\d+\.\d+\.\d+\.\d+$/)
      raise OpenShift::UserException.new("Invalid Server Alias '#{server_alias}' specified", 105)
    end
    
    Application.run_in_application_lock(self) do
      raise OpenShift::UserException.new("Alias #{server_alias} is already registered", 140) if Application.where(aliases: server_alias).count > 0
      aliases.push(server_alias)
      op_group = PendingAppOpGroup.new(op_type: :add_alias, args: {"fqdn" => server_alias}, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  # Removes a DNS alias for the application.
  #
  # == Parameters:
  # fqdn::
  #   Fully qualified domain name of the alias to remove from this application
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progress of the operation.
  def remove_alias(fqdn)
    fqdn = fqdn.downcase
    
    Application.run_in_application_lock(self) do
      raise OpenShift::UserException.new("Alias '#{fqdn}' does not exist for '#{self.name}'") unless aliases.include? fqdn
      
      aliases.delete(fqdn)
      op_group = PendingAppOpGroup.new(op_type: :remove_alias, args: {"fqdn" => fqdn}, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  def set_connections(connections)
    conns = []
    self.connections = [] if connections.nil? or connections.empty?
    connections.each do |conn_info|
      from_comp_inst = self.component_instances.find_by(cartridge_name: conn_info["from_comp_inst"]["cart"], component_name: conn_info["from_comp_inst"]["comp"])
      to_comp_inst = self.component_instances.find_by(cartridge_name: conn_info["to_comp_inst"]["cart"], component_name: conn_info["to_comp_inst"]["comp"])
      conns.push(ConnectionInstance.new(
        from_comp_inst_id: from_comp_inst._id, to_comp_inst_id: to_comp_inst._id,
        from_connector_name: conn_info["from_connector_name"], to_connector_name: conn_info["to_connector_name"],
        connection_type: conn_info["connection_type"]))
    end
    self.connections = conns
  end

  def execute_connections
    if self.scalable
      Rails.logger.debug "Running publishers"
      handle = RemoteJob.create_parallel_job
      #publishers
      sub_jobs = []
      self.connections.each do |conn|
        pub_inst = self.component_instances.find(conn.from_comp_inst_id)
        pub_ginst = self.group_instances.find(pub_inst.group_instance_id)
        tag = conn._id.to_s
  
        pub_ginst.gears.each_index do |idx|
          break if (pub_inst.is_singleton? && idx > 0)
          gear = pub_ginst.gears[idx]
          input_args = [gear.name, self.domain.namespace, gear._id.to_s]
          job = gear.get_execute_connector_job(pub_inst.cartridge_name, conn.from_connector_name, input_args)
          RemoteJob.add_parallel_job(handle, tag, gear, job)
        end
      end
      pub_out = {}
      RemoteJob.execute_parallel_jobs(handle)
      RemoteJob.get_parallel_run_results(handle) do |tag, gear_id, output, status|
        if status==0
          pub_out[tag] = [] if pub_out[tag].nil?
          pub_out[tag].push("'#{gear_id}'='#{output}'")
        end
      end
      Rails.logger.debug "Running subscribers"
      #subscribers
      handle = RemoteJob.create_parallel_job
      self.connections.each do |conn|
        sub_inst = self.component_instances.find(conn.to_comp_inst_id)
        sub_ginst = self.group_instances.find(sub_inst.group_instance_id)
        tag = ""
  
        unless pub_out[conn._id.to_s].nil?
          input_to_subscriber = Shellwords::shellescape(pub_out[conn._id.to_s].join(' '))
  
          Rails.logger.debug "Output of publisher - '#{pub_out}'"
          sub_ginst.gears.each_index do |idx|
            break if (sub_inst.is_singleton? && idx > 0)
            gear = sub_ginst.gears[idx]
  
            input_args = [gear.name, self.domain.namespace, gear._id.to_s, input_to_subscriber]
            job = gear.get_execute_connector_job(sub_inst.cartridge_name, conn.to_connector_name, input_args)
            RemoteJob.add_parallel_job(handle, tag, gear, job)
          end
        end
      end
      RemoteJob.execute_parallel_jobs(handle)
      Rails.logger.debug "Connections done"
    end
  end

  #private

  # Processes directives returned by component hooks to add/remove domain ssh keys, app ssh keys, env variables, broker keys etc
  # @note {#run_jobs} must be called in order to perform the updates
  #
  # == Parameters:
  # result_io::
  #   {ResultIO} object with directives from cartridge hooks
  def process_commands(result_io)
    commands = result_io.cart_commands
    add_ssh_keys = []
    remove_ssh_keys = []

    remove_env_vars = []

    domain_keys_to_add = []
    domain_keys_to_rm = []

    domain_env_vars_to_add = []
    domain_env_vars_to_rm = []

    commands.each do |command_item|
      case command_item[:command]
      when "SYSTEM_SSH_KEY_ADD"
        domain_keys_to_add.push(SystemSshKey.new(name: self.name, type: "ssh-rsa", content: command_item[:args][0]))
      when "SYSTEM_SSH_KEY_REMOVE"
        begin
          key = self.domain.system_ssh_keys.find_by(name: self.name)
          domain_keys_to_rm.push(key)
        rescue Mongoid::Errors::DocumentNotFound
          #ignore
        end
      when "APP_SSH_KEY_ADD"
        add_ssh_keys << ApplicationSshKey.new(name: "application-" + command_item[:args][0], type: "ssh-rsa", content: command_item[:args][1], created_at: Time.now)
      when "APP_SSH_KEY_REMOVE"
        begin
          remove_ssh_keys << self.app_ssh_keys.find_by(name: "application-" + command_item[:args][0])
        rescue Mongoid::Errors::DocumentNotFound
          #ignore
        end
      when "APP_ENV_VAR_REMOVE"
        remove_env_vars.push({"key" => command_item[:args][0]})
      when "ENV_VAR_ADD"
        domain_env_vars_to_add.push({"key" => command_item[:args][0], "value" => command_item[:args][1]})
      when "ENV_VAR_REMOVE"
        self.domain.env_vars.each {|env_var| domain_env_vars_to_rm << env_var if env_var["key"] == command_item[:args][0]}
      when "BROKER_KEY_ADD"
        iv, token = OpenShift::AuthService.instance.generate_broker_key(self)
        pending_op = PendingAppOpGroup.new(op_type: :add_broker_auth_key, args: { "iv" => iv, "token" => token }, user_agent: self.user_agent)
        Application.where(_id: self._id).update_all({ "$push" => { pending_op_groups: pending_op.serializable_hash } })
      when "BROKER_KEY_REMOVE"
        pending_op = PendingAppOpGroup.new(op_type: :remove_broker_auth_key, args: { }, user_agent: self.user_agent)
        Application.where(_id: self._id).update_all({ "$push" => { pending_op_groups: pending_op.serializable_hash } })
      end
    end

    if add_ssh_keys.length > 0
      keys_attrs = add_ssh_keys.map{|k| k.attributes.dup}
      pending_op = PendingAppOpGroup.new(op_type: :update_configuration, args: {"add_keys_attrs" => keys_attrs}, user_agent: self.user_agent)
      Application.where(_id: self._id).update_all({ "$push" => { pending_op_groups: pending_op.serializable_hash }, "$pushAll" => { app_ssh_keys: keys_attrs }})
    end
    if remove_ssh_keys.length > 0
      keys_attrs = remove_ssh_keys.map{|k| k.attributes.dup}
      pending_op = PendingAppOpGroup.new(op_type: :update_configuration, args: {"remove_keys_attrs" => keys_attrs}, user_agent: self.user_agent)
      Application.where(_id: self._id).update_all({ "$push" => { pending_op_groups: pending_op.serializable_hash }, "$pullAll" => { app_ssh_keys: keys_attrs }})
    end
    if remove_env_vars.length > 0
      pending_op = PendingAppOpGroup.new(op_type: :update_configuration, args: {"remove_env_vars" => remove_env_vars})
      Application.where(_id: self._id).update_all({ "$push" => { pending_op_groups: pending_op.serializable_hash }})
    end

    # Have to remember to run_jobs for the other apps involved at some point
    domain.remove_system_ssh_keys(domain_keys_to_rm) if !domain_keys_to_rm.empty?
    domain.remove_env_variables(domain_env_vars_to_rm) if !domain_env_vars_to_rm.empty?
    domain.add_system_ssh_keys(domain_keys_to_add) if !domain_keys_to_add.empty?
    domain.add_env_variables(domain_env_vars_to_add) if !domain_env_vars_to_add.empty?
    nil
  end

  # Acquires an application level lock and runs all pending jobs and stops at the first failure.
  #
  # == Returns:
  # True on success or False if unable to acquire the lock or no pending jobs.
  def run_jobs(result_io=nil)
    result_io = ResultIO.new if result_io.nil?
    self.with(consistency: :strong).reload
    return true if (self.pending_op_groups.count == 0)
    begin
      while self.pending_op_groups.count > 0
        op_group = self.pending_op_groups.first
        self.user_agent = op_group.user_agent
        op_group.pending_ops
        if op_group.pending_ops.count == 0
          case op_group.op_type
          when :update_namespace
            ops = calculate_namespace_ops(op_group.args)
            op_group.pending_ops.push(*ops)
          when :complete_update_namespace
            ops = calculate_complete_update_ns_ops(op_group.args)
            op_group.pending_ops.push(*ops)
          when :update_configuration
            ops = calculate_update_existing_configuration_ops(op_group.args)
            op_group.pending_ops.push(*ops)
          when :add_features
            #need rollback
            features = self.requires + op_group.args["features"]
            group_overrides = (self.group_overrides || []) + (op_group.args["group_overrides"] || [])
            ops, add_gear_count, rm_gear_count = update_requirements(features, group_overrides, op_group.args["init_git_url"])
            try_reserve_gears(add_gear_count, rm_gear_count, op_group, ops)
          when :remove_features
            #need rollback
            features = self.requires - op_group.args["features"]
            group_overrides = (self.group_overrides || []) + (op_group.args["group_overrides"] || [])
            ops, add_gear_count, rm_gear_count = update_requirements(features, group_overrides)
            try_reserve_gears(add_gear_count, rm_gear_count, op_group, ops)
          when :update_component_limits
            updated_overrides = deep_copy(self.group_overrides || [])
            found = updated_overrides.find {|go| go["components"].include? op_group.args["comp_spec"] }
            group_override = found || {"components" => [op_group.args["comp_spec"]]}
            group_override["min_gears"] = op_group.args["min"] unless op_group.args["min"].nil?
            group_override["max_gears"] = op_group.args["max"] unless op_group.args["max"].nil?
            group_override["additional_filesystem_gb"] = op_group.args["additional_filesystem_gb"] unless op_group.args["additional_filesystem_gb"].nil?
            updated_overrides.push(group_override) unless found
            features = self.requires
            ops, add_gear_count, rm_gear_count = update_requirements(features, updated_overrides)
            try_reserve_gears(add_gear_count, rm_gear_count, op_group, ops)
          when :delete_app
            self.pending_op_groups.clear
            self.delete
          when :remove_gear
            ops = calculate_remove_gear_ops(op_group.args)
            op_group.pending_ops.push(*ops)
          when :scale_by
            #need rollback
            ops, add_gear_count, rm_gear_count = calculate_scale_by(op_group.args["group_instance_id"], op_group.args["scale_by"])
            try_reserve_gears(add_gear_count, rm_gear_count, op_group, ops)
          when :add_alias
            self.group_instances.each do |group_instance|
              if group_instance.gears.where(app_dns: true).count > 0
                gear = group_instance.gears.find_by(app_dns: true)
                op_group.pending_ops.push PendingAppOp.new(op_type: :add_alias, args: {"group_instance_id" => group_instance.id.to_s, "gear_id" => gear.id.to_s, "fqdn" => op_group.args["fqdn"]} )
                break
              end
            end
          when :remove_alias
            self.group_instances.each do |group_instance|
              if group_instance.gears.where(app_dns: true).count > 0
                gear = group_instance.gears.find_by(app_dns: true)
                op_group.pending_ops.push PendingAppOp.new(op_type: :remove_alias, args: {"group_instance_id" => group_instance.id.to_s, "gear_id" => gear.id.to_s, "fqdn" => op_group.args["fqdn"]} )
                break
              end
            end
          when :add_broker_auth_key, :remove_broker_auth_key
            ops = []
            args = op_group.args.dup
            self.group_instances.each do |group_instance|
              args["group_instance_id"] = group_instance._id.to_s
              group_instance.gears.each do |gear|
                args["gear_id"] = gear._id.to_s
                ops.push(PendingAppOp.new(op_type: op_group.op_type, args: args.dup))
              end
            end
            op_group.pending_ops.push(*ops)
          when :start_app, :stop_app, :restart_app, :reload_app_config, :tidy_app
            ops = calculate_ctl_app_component_ops(op_group.op_type)
            op_group.pending_ops.push(*ops)
          when :start_feature, :stop_feature, :restart_feature, :reload_feature_config
            ops = calculate_ctl_feature_component_ops(op_group.op_type, op_group.args['feature'])
            op_group.pending_ops.push(*ops)
          when :start_component, :stop_component, :restart_component, :reload_component_config
            ops = calculate_ctl_component_ops(op_group.op_type, op_group.args['comp_spec'])
            op_group.pending_ops.push(*ops)
          end
        end

        if op_group.op_type != :delete_app
          op_group.execute(result_io)
          unreserve_gears(op_group.num_gears_removed)
          op_group.delete
          self.with(consistency: :strong).reload
        end
        
      end
      true
    rescue Exception => e_orig
      Rails.logger.error e_orig.message
      Rails.logger.debug e_orig.backtrace.inspect

      #rollback
      begin
        op_group.execute_rollback(result_io)
      rescue Exception => e_rollback
        Rails.logger.error "Error during rollback"
        Rails.logger.error e_rollback.message
        Rails.logger.error e_rollback.backtrace.inspect
      ensure
        num_gears_recovered = op_group.num_gears_added - op_group.num_gears_created + op_group.num_gears_rolled_back + op_group.num_gears_destroyed
        unreserve_gears(num_gears_recovered)
        op_group.delete
      end
      raise e_orig
    end
  end
  
  def self.run_in_application_lock(application, &block)
    got_lock = false
    num_retries = 10
    wait = 5
    while(num_retries > 0 and !got_lock)  
      if(Lock.lock_application(application))
        got_lock = true
      else
        num_retries -= 1
        sleep(wait)
      end
    end 
    if got_lock
      begin
        yield block
      ensure
        Lock.unlock_application(application)
      end
    else
      raise OpenShift::LockUnavailableException.new("Unable to perform action. Another operation is already running.", 171)
    end
  end

  def calculate_remove_gear_ops(args, prereqs={})
    gear_id = args["gear_id"]
    group_instance = self.group_instances.find { |gi| gi.gears.find { |g| g._id.to_s==gear_id.to_s } }
    return [] if group_instance.nil?
    ops=calculate_gear_destroy_ops(group_instance._id.to_s, [gear_uuid], group_instance.addtl_fs_gb)
    last_op = ops.last
    ops.push PendingAppOp.new(op_type: :execute_connections, prereq: last_op)
    ops
  end

  def calculate_complete_update_ns_ops(args, prereqs={})
    ops = []
    last_op = nil
    last_op_id = nil
    old_ns = args["old_namespace"]
    new_ns = args["new_namespace"]
    self.group_instances.each do |group_instance|
      args["group_instance_id"] = group_instance._id.to_s
      group_instance.all_component_instances.each do |component_instance|
        args["comp_spec"] = {"comp" => component_instance.component_name, "cart" => component_instance.cartridge_name}
        last_op_id = last_op._id.to_s if last_op
        last_op = PendingAppOp.new(op_type: :complete_update_namespace, args: args.dup, prereq: [last_op_id])
        ops.push last_op
      end
    end
    last_op_id = last_op._id.to_s if last_op
    ops.push PendingAppOp.new(op_type: :execute_connections, prereq: [last_op_id])
    # self.domain.namespace = new_ns
    ops
  end

  def calculate_namespace_ops(args, prereqs={})
    ops = []
    self.group_instances.each do |group_instance|
      args["group_instance_id"] = group_instance._id.to_s
      args["cartridge"] = "abstract"
      group_instance.gears.each do |gear|
        args["gear_id"] = gear._id.to_s
        ops.push(PendingAppOp.new(op_type: :update_namespace, args: args.dup, prereq: prereqs))
      end
    end
    ops
  end

  def update_requirements(features, group_overrides, init_git_url=nil)
    group_overrides = (group_overrides + gen_non_scalable_app_overrides(features)).uniq unless self.scalable
    
    connections, new_group_instances, cleaned_group_overrides = elaborate(features, group_overrides)
    current_group_instance = self.group_instances.map { |gi| gi.to_hash }
    changes, moves = compute_diffs(current_group_instance, new_group_instances)
    
    calculate_ops(changes, moves, connections, cleaned_group_overrides,init_git_url)
  end

  def calculate_update_existing_configuration_ops(args, prereqs={})
    ops = []

    if (args.has_key?("add_keys_attrs") or args.has_key?("remove_keys_attrs") or args.has_key?("add_env_vars") or args.has_key?("remove_env_vars"))
      self.group_instances.each do |group_instance|
        args["group_instance_id"] = group_instance._id.to_s
        group_instance.gears.each do |gear|
          prereq = prereqs[gear._id.to_s].nil? ? [] : [prereqs[gear._id.to_s]]
          args["gear_id"] = gear._id.to_s
          ops.push(PendingAppOp.new(op_type: :update_configuration, args: args.dup, prereq: prereq))
        end
      end
    end
    ops
  end

  def calculate_update_new_configuration_ops(args, group_instance_id, gear_id_prereqs)
    ops = []

    if (args.has_key?("add_keys_attrs") or args.has_key?("remove_keys_attrs") or args.has_key?("add_env_vars") or args.has_key?("remove_env_vars"))
      args["group_instance_id"] = group_instance_id
      gear_id_prereqs.each_key do |gear_id|
        args["gear_id"] = gear_id
        prereq = gear_id_prereqs[gear_id].nil? ? [] : [gear_id_prereqs[gear_id]]
        ops.push(PendingAppOp.new(op_type: :update_configuration, args: args.dup, prereq: prereq))
      end
    end
    ops
  end

  def calculate_scale_by(ginst_id, scale_by)
    changes = []
    current_group_instances = group_instances_with_scale
    current_group_instances.each do |ginst|
      if ginst._id.to_s == ginst_id.to_s
        final_scale = ginst.gears.length + scale_by
        final_scale = ginst.min if final_scale < ginst.min
        final_scale = ginst.max if ((final_scale > ginst.max) && (ginst.max != -1))

        changes << {
          :from=>ginst_id.to_s, :to=>ginst_id.to_s,
          :added=>[], :removed=>[], 
          :from_scale=>{:min=>ginst.min, :max=>ginst.max, :current=>ginst.gears.length},
          :to_scale=>{:min=>ginst.min, :max=>ginst.max, :current=>final_scale}
        }
      end
    end
    calculate_ops(changes)
  end

  def calculate_remove_group_instance_ops(comp_specs, group_instance)
    pending_ops = []
    gear_destroy_ops = calculate_gear_destroy_ops(group_instance._id.to_s, group_instance.gears.map{|g| g._id.to_s}, group_instance.addtl_fs_gb)
    pending_ops.push(*gear_destroy_ops)
    gear_destroy_op_ids = gear_destroy_ops.map{|op| op._id.to_s}

    delete_comp_ops = []
    comp_specs.each do |comp_spec|
      delete_comp_ops.push(PendingAppOp.new(op_type: :del_component, args: {"group_instance_id"=> group_instance._id.to_s, "comp_spec" => comp_spec}, prereq: gear_destroy_op_ids))
    end
    pending_ops.push(*delete_comp_ops)
    comp_delete_op_ids = delete_comp_ops.map{|op| op._id.to_s}
    
    destroy_ginst_op  = PendingAppOp.new(op_type: :destroy_group_instance, args: {"group_instance_id"=> group_instance._id.to_s}, prereq: gear_destroy_op_ids + comp_delete_op_ids)
    pending_ops.push(destroy_ginst_op)
    
    pending_ops
  end

  def calculate_gear_create_ops(ginst_id, gear_ids, singleton_gear_id, comp_specs, component_ops, additional_filesystem_gb, gear_size, ginst_op_id=nil, is_scale_up=false, hosts_app_dns=false, init_git_url=nil)
    pending_ops = []

    a_ssh_keys = self.app_ssh_keys.map{|k| k.attributes}
    d_ssh_keys = get_updated_ssh_keys(nil, self.domain.system_ssh_keys.map{|k| k.attributes})
    o_ssh_keys = get_updated_ssh_keys(self.domain.owner._id, self.domain.owner.ssh_keys.map{|k| k.attributes})
    u_ssh_keys = CloudUser.find(self.domain.user_ids).map{|u| get_updated_ssh_keys(u._id, u.ssh_keys.map{|k| k.attributes})}.flatten
    
    ssh_keys = a_ssh_keys + d_ssh_keys + o_ssh_keys + u_ssh_keys
    env_vars = self.domain.env_vars
    init_git_url = nil unless hosts_app_dns

    gear_id_prereqs = {}
    gear_ids.each do |gear_id|
      host_singletons = (gear_id == singleton_gear_id)
      app_dns = (host_singletons && hosts_app_dns)
      init_gear_op = PendingAppOp.new(op_type: :init_gear,   args: {"group_instance_id"=> ginst_id, "gear_id" => gear_id, "host_singletons" => host_singletons, "app_dns" => app_dns})
      init_gear_op.prereq = [ginst_op_id] unless ginst_op_id.nil?
      reserve_uid_op  = PendingAppOp.new(op_type: :reserve_uid,  args: {"group_instance_id"=> ginst_id, "gear_id" => gear_id}, prereq: [init_gear_op._id.to_s])
      create_gear_op    = PendingAppOp.new(op_type: :create_gear,  args: {"group_instance_id"=> ginst_id, "gear_id" => gear_id}, prereq: [reserve_uid_op._id.to_s], retry_rollback_op: reserve_uid_op._id.to_s)
      track_usage_op = PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => gear_id, "event" => UsageRecord::EVENTS[:begin], 
          "usage_type" => UsageRecord::USAGE_TYPES[:gear_usage], "gear_size" => gear_size}, prereq: [create_gear_op._id.to_s])
      register_dns_op = PendingAppOp.new(op_type: :register_dns, args: {"group_instance_id"=> ginst_id, "gear_id" => gear_id}, prereq: [create_gear_op._id.to_s])
      pending_ops.push(init_gear_op)
      pending_ops.push(reserve_uid_op)
      pending_ops.push(create_gear_op)
      pending_ops.push(track_usage_op)      
      pending_ops.push(register_dns_op)

      if additional_filesystem_gb != 0
        fs_op           = PendingAppOp.new(op_type: :set_gear_additional_filesystem_gb, 
          args: {"group_instance_id"=> ginst_id, "gear_id" => gear_id, "additional_filesystem_gb" => additional_filesystem_gb}, 
          prereq: [create_gear_op._id.to_s],
          saved_values: {"additional_filesystem_gb" => 0})
        pending_ops.push(fs_op)

        track_usage_fs_op = PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => gear_id, "event" => UsageRecord::EVENTS[:begin],
          "usage_type" => UsageRecord::USAGE_TYPES[:addtl_fs_gb], "additional_filesystem_gb" => additional_filesystem_gb}, prereq: [fs_op._id.to_s])
        pending_ops.push(track_usage_fs_op)
      end

      gear_id_prereqs[gear_id] = register_dns_op._id.to_s
    end

    ops = calculate_update_new_configuration_ops({"add_keys_attrs" => ssh_keys, "add_env_vars" => env_vars}, ginst_id, gear_id_prereqs)
    pending_ops.push(*ops)

    ops = calculate_add_component_ops(comp_specs, ginst_id, gear_id_prereqs, singleton_gear_id, component_ops, is_scale_up, ginst_op_id, init_git_url)
    pending_ops.push(*ops)
    pending_ops
  end

  def calculate_gear_destroy_ops(ginst_id, gear_ids, additional_filesystem_gb)
    pending_ops = []
    delete_gear_op = nil
    gear_ids.each do |gear_id|
      destroy_gear_op   = PendingAppOp.new(op_type: :destroy_gear,   args: {"group_instance_id"=> ginst_id, "gear_id" => gear_id})
      deregister_dns_op = PendingAppOp.new(op_type: :deregister_dns, args: {"group_instance_id"=> ginst_id, "gear_id" => gear_id}, prereq: [destroy_gear_op._id.to_s])
      unreserve_uid_op  = PendingAppOp.new(op_type: :unreserve_uid,  args: {"group_instance_id"=> ginst_id, "gear_id" => gear_id}, prereq: [deregister_dns_op._id.to_s])
      delete_gear_op    = PendingAppOp.new(op_type: :delete_gear,    args: {"group_instance_id"=> ginst_id, "gear_id" => gear_id}, prereq: [unreserve_uid_op._id.to_s])
      track_usage_op    = PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => gear_id, "event" => UsageRecord::EVENTS[:end], 
          "usage_type" => UsageRecord::USAGE_TYPES[:gear_usage]}, prereq: [delete_gear_op._id.to_s])
      
      ops = [destroy_gear_op, deregister_dns_op, unreserve_uid_op, delete_gear_op, track_usage_op]
      pending_ops.push *ops
      if additional_filesystem_gb != 0
        track_usage_fs_op = PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => gear_id, "event" => UsageRecord::EVENTS[:end],
          "usage_type" => UsageRecord::USAGE_TYPES[:addtl_fs_gb], "additional_filesystem_gb" => additional_filesystem_gb}, prereq: [delete_gear_op._id.to_s])
        pending_ops.push(track_usage_fs_op)
      end
    end
    comp_specs = self.group_instances.find(ginst_id).all_component_instances.map{ |c| c.to_hash }
    comp_specs.each do |comp_spec|
      cartridge = CartridgeCache.find_cartridge(comp_spec["cart"])
      gear_ids.each do |gear_id|
        pending_ops.push(PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => gear_id, "event" => UsageRecord::EVENTS[:end], 
          "usage_type" => UsageRecord::USAGE_TYPES[:premium_cart], "cart_name" => comp_spec["cart"]}, prereq: [delete_gear_op._id.to_s]))
      end if cartridge.is_premium?
    end
    pending_ops
  end

  def calculate_add_component_ops(comp_specs, group_instance_id, gear_id_prereqs, singleton_gear_id, component_ops, is_scale_up, new_group_instance_op_id, init_git_url=nil)
    ops = []

    comp_specs.each do |comp_spec|
      component_ops[comp_spec] = {new_component: nil, adds: []} if component_ops[comp_spec].nil?
      cartridge = CartridgeCache.find_cartridge(comp_spec["cart"])
      is_singleton = cartridge.get_component(comp_spec["comp"]).is_singleton?

      new_component_op_id = []
      unless is_scale_up
        new_component_op = PendingAppOp.new(op_type: :new_component, args: {"group_instance_id"=> group_instance_id, "comp_spec" => comp_spec}, prereq: [new_group_instance_op_id])
        component_ops[comp_spec][:new_component] = new_component_op
        new_component_op_id = [new_component_op._id.to_s]
        ops.push new_component_op
      end

      if is_singleton
        if gear_id_prereqs.keys.include?(singleton_gear_id)
          prereq_id = gear_id_prereqs[singleton_gear_id]
          op = PendingAppOp.new(op_type: :add_component, args: {"group_instance_id"=> group_instance_id, "gear_id" => singleton_gear_id, "comp_spec" => comp_spec, "init_git_url"=>init_git_url}, prereq: new_component_op_id + [prereq_id])
          ops.push op
          component_ops[comp_spec][:adds].push op
          ops.push(PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => singleton_gear_id, "event" => UsageRecord::EVENTS[:begin], 
            "usage_type" => UsageRecord::USAGE_TYPES[:premium_cart], "cart_name" => comp_spec["cart"]}, prereq: [op._id.to_s])) if cartridge.is_premium?
        end
      else
        gear_id_prereqs.each do |gear_id, prereq_id|
          git_url = nil
          git_url = init_git_url if gear_id == singleton_gear_id
          op = PendingAppOp.new(op_type: :add_component, args: {"group_instance_id"=> group_instance_id, "gear_id" => gear_id, "comp_spec" => comp_spec, "init_git_url"=>git_url}, prereq: new_component_op_id + [prereq_id])
          ops.push op
          component_ops[comp_spec][:adds].push op
          ops.push(PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => gear_id, "event" => UsageRecord::EVENTS[:begin], 
            "usage_type" => UsageRecord::USAGE_TYPES[:premium_cart], "cart_name" => comp_spec["cart"]}, prereq: [op._id.to_s])) if cartridge.is_premium?
        end
      end
    end

    if self.scalable
      last_op = ops.last
      expose_prereqs = []
      expose_prereqs << last_op._id.to_s unless last_op.nil?

      comp_specs.each do |comp_spec|
        gear_id_prereqs.each do |gear_id, prereq_id|
          op = PendingAppOp.new(op_type: :expose_port, args: { "group_instance_id" => group_instance_id, "gear_id" => gear_id, "comp_spec" => comp_spec }, prereq: expose_prereqs + [prereq_id])
          ops.push op
        end
      end
    end
    ops
  end

  def calculate_ctl_component_ops(op_type, comp_spec)
    component_instance = self.component_instances.find_by(cartridge_name: comp_spec['cart'], component_name: comp_spec['comp'])
    ops = []
    add_component_ops(op_type, component_instance, ops)
    ops
  end
  
  def calculate_ctl_app_component_ops(op_type)
    ops = []
    start_order, stop_order = calculate_component_orders
    order = (op_type == :stop_app) ? stop_order : start_order
    order.each do |component_instance|
      add_component_ops(op_type_to_comp_op_type(op_type), component_instance, ops)
    end
    ops
  end
  
  def calculate_ctl_feature_component_ops(op_type, feature)
    ops = []
    component_instances = get_components_for_feature(feature)
    start_order, stop_order = calculate_component_orders
    order = op_type == :stop_feature ? stop_order : start_order
    order.each do |component_instance|
      if component_instances.include? component_instance
        add_component_ops(op_type_to_comp_op_type(op_type), component_instance, ops)
      end
    end
    ops
  end
  
  def add_component_ops(op_type, component_instance, ops)
    component_instance.group_instance.gears.each do |gear| 
      op = PendingAppOp.new(op_type: op_type, args: {'group_instance_id' => component_instance.group_instance._id, 'gear_id' => gear._id, 'comp_spec' => {'cart' => component_instance.cartridge_name, 'comp' => component_instance.component_name}})
      ops.push op
    end
  end
  
  def op_type_to_comp_op_type(op_type)
    comp_op_type = nil
    case op_type
    when :start_app, :start_feature
      comp_op_type = :start_component 
    when :stop_app, :stop_feature
      comp_op_type = :stop_component
    when :restart_app, :restart_feature
      comp_op_type = :restart_component 
    when :reload_app_config, :reload_feature_config
      comp_op_type = :reload_component_config 
    when :tidy_app
      comp_op_type = :tidy_component
    end
    comp_op_type
  end

  def calculate_remove_component_ops(comp_specs, group_instance, singleton_gear)
    ops = []
    comp_specs.each do |comp_spec|
      component_instance = self.component_instances.find_by(cartridge_name: comp_spec["cart"], component_name: comp_spec["comp"])
      cartridge = CartridgeCache.find_cartridge(comp_spec["cart"])
      if component_instance.is_plugin? || (!self.scalable && component_instance.is_embeddable?)
        if component_instance.is_singleton?
          op = PendingAppOp.new(op_type: :remove_component, args: {"group_instance_id"=> group_instance._id.to_s, "gear_id" => singleton_gear._id.to_s, "comp_spec" => comp_spec})
          ops.push op
          ops.push(PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => singleton_gear._id.to_s, "event" => UsageRecord::EVENTS[:end], 
            "usage_type" => UsageRecord::USAGE_TYPES[:premium_cart], "cart_name" => comp_spec["cart"]}, prereq: [op._id.to_s])) if cartridge.is_premium?
        else
          group_instance.gears.each do |gear|
            op = PendingAppOp.new(op_type: :remove_component, args: {"group_instance_id"=> group_instance._id.to_s, "gear_id" => gear._id, "comp_spec" => comp_spec})
            ops.push op
            ops.push(PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => gear._id.to_s, "event" => UsageRecord::EVENTS[:end],
              "usage_type" => UsageRecord::USAGE_TYPES[:premium_cart], "cart_name" => comp_spec["cart"]}, prereq: [op._id.to_s])) if cartridge.is_premium?
          end
        end
      end
      ops.push(PendingAppOp.new(op_type: :del_component, args: {"group_instance_id"=> group_instance._id.to_s, "comp_spec" => comp_spec}, prereq: ops.map{|o| o._id.to_s}))
    end
    ops
  end

  # Given a set of changes, moves and connections, calculates all the operations required to update the application.
  #
  # == Parameters:
  # changes::
  #   Changes needed to the current_group_instances to make it match the new_group_instances. (Includes all adds/removes). (Output of {#compute_diffs} or {#scale_by})
  #
  # moves::
  #   A list of components which need to move from one group instance to another. (Output of {#compute_diffs})
  #
  # connections::
  #   An array of connections. (Output of {#elaborate})
  def calculate_ops(changes,moves=[],connections=nil,group_overrides=nil,init_git_url=nil)
    app_dns_ginst_found = false
    add_gears = 0
    remove_gears = 0
    pending_ops = []
    start_order, stop_order = calculate_component_orders

    unless group_overrides.nil?
      set_group_override_op = PendingAppOp.new(op_type: :set_group_overrides, args: {"group_overrides"=> group_overrides}, saved_values: {"group_overrides" => self.group_overrides})
      pending_ops.push set_group_override_op
    end

    component_ops = {}
    # Create group instances and gears in preperation formove or add component operations
    create_ginst_changes = changes.select{ |change| change[:from].nil? }
    create_ginst_changes.each do |change|
      ginst_scale = change[:to_scale][:current] || 1
      ginst_id    = change[:to]
      gear_size = change[:to_scale][:gear_size] || "small"
      additional_filesystem_gb = change[:to_scale][:additional_filesystem_gb] || 0
      add_gears   += ginst_scale if ginst_scale > 0

      ginst_op = PendingAppOp.new(op_type: :create_group_instance, args: {"group_instance_id"=> ginst_id})
      ginst_op.prereq << set_group_override_op._id.to_s unless set_group_override_op.nil?
      pending_ops.push(ginst_op)
      gear_ids = (1..ginst_scale).map {|idx| Moped::BSON::ObjectId.new.to_s}

      comp_specs = change[:added]
      app_dns_ginst = false
      comp_specs.each do |comp_spec|
        cats = CartridgeCache.find_cartridge(comp_spec["cart"]).categories
        app_dns_ginst = true if cats.include?("web_framework") || cats.include?("web_proxy")
      end

      if app_dns_ginst
        singleton_gear_id = gear_ids[0] = self._id.to_s
      else
        singleton_gear_id = gear_ids[0]
      end

      ops = calculate_gear_create_ops(ginst_id, gear_ids, singleton_gear_id, comp_specs, component_ops, additional_filesystem_gb, gear_size, ginst_op._id.to_s, false, app_dns_ginst,init_git_url)
      pending_ops.push *ops
    end

    moves.each do |move|
      #ops.push(PendingAppOps.new(op_type: :move_component, args: move, flag_req_change: true))
    end


    changes.each do |change|
      unless change[:from].nil?
        group_instance = self.group_instances.find(change[:from])
        if change[:to].nil?
          remove_gears += change[:from_scale][:current]

          group_instance_remove_ops = calculate_remove_group_instance_ops(change[:removed], group_instance)
          pending_ops.push(*group_instance_remove_ops)
        else
          scale_change = 0
          if change[:to_scale][:current].nil?
            if change[:from_scale][:current] < change[:to_scale][:min]
              scale_change += change[:to_scale][:min] - change[:from_scale][:current]
            end
            if((change[:from_scale][:current] > change[:to_scale][:max]) && (change[:to_scale][:max] != -1))
              scale_change -= change[:from_scale][:current] - change[:to_scale][:max]
            end
          else
            scale_change += (change[:to_scale][:current] - change[:from_scale][:current])
          end

          singleton_gear = group_instance.gears.find_by(host_singletons: true)
          ops = calculate_remove_component_ops(change[:removed], group_instance, singleton_gear)
          pending_ops.push(*ops)

          gear_id_prereqs = {}
          group_instance.gears.each{|g| gear_id_prereqs[g._id.to_s] = []}
          ops = calculate_add_component_ops(change[:added], change[:from], gear_id_prereqs, singleton_gear._id.to_s, component_ops, false, nil)
          pending_ops.push(*ops)

          changed_additional_filesystem_gb = nil
          #add/remove fs space from existing gears
          if change[:from_scale][:additional_filesystem_gb] != change[:to_scale][:additional_filesystem_gb]
            changed_additional_filesystem_gb = change[:to_scale][:additional_filesystem_gb]
            usage_prereq = []
            usage_prereq = [pending_ops.last._id.to_s] if pending_ops.last
            usage_ops = []
            if change[:from_scale][:additional_filesystem_gb] != 0
              group_instance.gears.each do |gear|
                track_usage_old_fs_op = PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => gear._id.to_s,
                  "event" => UsageRecord::EVENTS[:end], "usage_type" => UsageRecord::USAGE_TYPES[:addtl_fs_gb], "additional_filesystem_gb" => change[:from_scale][:additional_filesystem_gb]}, prereq: usage_prereq)
                usage_ops.push(track_usage_old_fs_op._id.to_s)
                pending_ops.push(track_usage_old_fs_op)
              end
            end
            group_instance.gears.each do |gear|
              fs_op = PendingAppOp.new(op_type: :set_gear_additional_filesystem_gb, 
                  args: {"group_instance_id"=> group_instance._id.to_s, "gear_id" => gear._id.to_s, "additional_filesystem_gb" => change[:to_scale][:additional_filesystem_gb]}, 
                  saved_values: {"additional_filesystem_gb" => change[:from_scale][:additional_filesystem_gb]}, 
                  prereq: (usage_ops.empty?? usage_prereq : usage_ops))
              pending_ops.push(fs_op)

              if change[:to_scale][:additional_filesystem_gb] != 0
                track_usage_fs_op = PendingAppOp.new(op_type: :track_usage, args: {"login" => self.domain.owner.login, "app_name" => self.name, "gear_ref" => gear._id.to_s,
                    "event" => UsageRecord::EVENTS[:begin], "usage_type" => UsageRecord::USAGE_TYPES[:addtl_fs_gb], "additional_filesystem_gb" => change[:to_scale][:additional_filesystem_gb]}, prereq: [fs_op._id.to_s])
                pending_ops.push(track_usage_fs_op)
              end
            end
          end

          if scale_change > 0
            add_gears += scale_change
            comp_specs = self.component_instances.where(group_instance_id: group_instance._id).map{|c| c.to_hash}
            singleton_gear = group_instance.gears.find_by(host_singletons: true)
            gear_ids = (1..scale_change).map {|idx| Moped::BSON::ObjectId.new.to_s}
            additional_filesystem_gb = changed_additional_filesystem_gb || group_instance.addtl_fs_gb
            gear_size = change[:to_scale][:gear_size] || group_instance.gear_size

            ops = calculate_gear_create_ops(change[:from], gear_ids, singleton_gear._id.to_s, comp_specs, component_ops, additional_filesystem_gb, gear_size, nil, true)
            pending_ops.push *ops
          end

          if scale_change < 0
            remove_gears += -scale_change
            ginst = self.group_instances.find(change[:from])
            gears = ginst.gears[(ginst.gears.length + scale_change)..-1]
            remove_ids = gears.map{|g| g._id.to_s}
            ops = calculate_gear_destroy_ops(ginst._id.to_s, remove_ids, ginst.addtl_fs_gb)
            pending_ops.push(*ops)
          end
        end
      end
    end

    config_order = calculate_configure_order(component_ops.keys)
    config_order.each_index do |idx|
      next if idx == 0
      prereq_ids = component_ops[config_order[idx-1]][:adds].map{|op| op._id.to_s}

      component_ops[config_order[idx]][:new_component].prereq += prereq_ids unless component_ops[config_order[idx]][:new_component].nil?
      component_ops[config_order[idx]][:adds].each { |op| op.prereq += prereq_ids }
    end

    all_ops_ids = pending_ops.map{ |op| op._id.to_s }
    unless connections.nil?
      #needs to be set and run after all the gears are in place
      saved_connections = self.connections.map{|conn| conn.to_hash}
      set_connections_op = PendingAppOp.new(op_type: :set_connections, args: {"connections"=> connections}, prereq: all_ops_ids, saved_values: {connections: saved_connections})
      execute_connection_op = PendingAppOp.new(op_type: :execute_connections, prereq: [set_connections_op._id.to_s])
      pending_ops.push set_connections_op
      pending_ops.push execute_connection_op
    else
      execute_connection_op = PendingAppOp.new(op_type: :execute_connections, prereq: all_ops_ids)
      pending_ops.push execute_connection_op
    end

    [pending_ops, add_gears, remove_gears]
  end

  # Computes the changes (moves, additions, deletions) required to move from the current set of group instances/components to
  # a new set.
  #
  # == Parameters:
  # current_group_instances::
  #   Group instance list containing information about current group instances. Expected format:
  #     [ {component_instances: [{cart: <cart name>, comp: <comp name>}...], _id: <uuid>, scale: {min: <min scale>, max: <max scale>, current: <current scale>}}...]
  # new_group_instances::
  #   New set of group instances as computed by the elaborate function
  #
  # == Returns:
  # changes::
  #   Changes needed to the current_group_instances to make it match the new_group_instances. (Includes all adds/removes)
  # moves::
  #   A list of components which need to move from one group instance to another
  def compute_diffs(current_group_instances, new_group_instances)
    axis_size = current_group_instances.length + new_group_instances.length
    cost_matrix = Matrix.build(axis_size,axis_size){0}
    #compute cost of moves
    (0..axis_size-1).each do |from|
      (0..axis_size-1).each do |to|
        gi_from = current_group_instances[from].nil? ? [] : current_group_instances[from][:component_instances]
        gi_to   = new_group_instances[to].nil? ? [] : new_group_instances[to][:component_instances]

        move_away = gi_from - gi_to
        move_in   = gi_to - gi_from
        cost_matrix[from,to] = move_away.length + move_in.length
      end
    end

    #compute changes
    changes = []
    (0..axis_size-1).each do |from|
      best_to = cost_matrix.row_vectors[from].to_a.index(cost_matrix.row_vectors[from].min)
      from_id = nil
      from_comp_insts = []
      to_comp_insts   = []
      from_scale      = {min: 1, max: MAX_SCALE, current: 0, additional_filesystem_gb: 0, gear_size: "small"}
      to_scale        = {min: 1, max: MAX_SCALE}

      unless current_group_instances[from].nil?
        from_comp_insts = current_group_instances[from][:component_instances]
        from_id         = current_group_instances[from][:_id]
        from_scale      = current_group_instances[from][:scale]
      end

      unless new_group_instances[best_to].nil?
        to_comp_insts = new_group_instances[best_to][:component_instances]
        to_scale      = new_group_instances[best_to][:scale]
        to_id         = from_id || new_group_instances[best_to][:_id]
      end
      unless from_comp_insts.empty? and to_comp_insts.empty?
        added = to_comp_insts - from_comp_insts
        removed = from_comp_insts - to_comp_insts
        changes << {from: from_id, to: to_id, added: added, removed: removed, from_scale: from_scale, to_scale: to_scale}
      end
      (0..axis_size-1).each {|i| cost_matrix[i,best_to] = 1000}
    end

    moves = []
    changes.each do |c1|
      c1[:removed].each do |comp_spec|
        changes.each do |c2|
          if c2[:added].include?(comp_spec)
            from_id = c1[:from].nil? ? nil : c1[:from]
            to_id = c2[:to].nil? ? nil : c2[:to]
            moves << {component: comp_spec, from_group_instance_id: from_id, to_group_instance_id: to_id}
            c1[:removed].delete comp_spec
            c2[:added].delete comp_spec
            break
          end
        end
      end
    end

    [changes, moves]
  end

  # Persists change operation only if the additonal number of gears requested are available on the domain owner
  #
  # == Parameters:
  # num_gears::
  #   Number of gears to add or remove
  #
  # ops::
  #   Array of pending operations.
  #   @see {PendingAppOps}
  def try_reserve_gears(num_gears_added, num_gears_removed, op_group, ops)
    owner = self.domain.owner
    begin
      until Lock.lock_user(owner, self)
        sleep 1
      end
      owner.with(consistency: :strong).reload
      owner_capabilities = owner.get_capabilities
      if owner.consumed_gears + num_gears_added > owner_capabilities["max_gears"]
        raise OpenShift::GearLimitReachedException.new("#{owner.login} is currently using #{owner.consumed_gears} out of #{owner_capabilities["max_gears"]} limit and this application requires #{num_gears_added} additional gears.")
      end
      owner.consumed_gears += num_gears_added
      op_group.pending_ops.push ops
      op_group.num_gears_added = num_gears_added
      op_group.num_gears_removed = num_gears_removed
      op_group.save
      owner.save
    ensure
      Lock.unlock_user(owner, self)
    end
  end

  def unreserve_gears(num_gears_removed)
    return if num_gears_removed == 0
    owner = self.domain.owner
    begin
      until Lock.lock_user(owner, self)
        sleep 1
      end
      owner.with(consistency: :strong).reload
      owner.consumed_gears -= num_gears_removed
      owner.save
    ensure
      Lock.unlock_user(owner, self)
    end
  end

  def process_group_overrides(component_instances, group_overrides)
    overrides = group_overrides ? deep_copy(group_overrides) : []
    cleaned_overrides = []
    
    # Resolve additional group overrides from component_instances
    component_instances.each do |component_instance|
      cart = CartridgeCache.find_cartridge(component_instance["cart"])
      prof = cart.profile_for_feature(component_instance["comp"])
      prof = prof[0] if prof.is_a?(Array)
      comp = prof.get_component(component_instance["comp"])
      overrides += deep_copy(prof.group_overrides)
      component_go = {"components" => [{"cart" => cart.name, "comp" => comp.name}] }
      if !comp.is_singleton? 
        component_go["min_gears"] = comp.scaling.min
        component_go["max_gears"] = comp.scaling.max
      end
      overrides <<  component_go
    end

    # Resolve all components within the group overrides
    # Remove deleted components from group_overrides and build cleaned_overrides array
    overrides.each do |group_override|
      cleaned_override = {}
      cleaned_override["components"] ||= []
      
      group_override["components"].map! do |comp_spec|
        comp_spec = {"comp" => comp_spec} if comp_spec.class == String
        component = component_instances.select{|ci| ci["comp"] == comp_spec["comp"] && (comp_spec["cart"].nil? || ci["cart"] == comp_spec["cart"])}
        next if component.size == 0
        component = component.first

        cleaned_override["components"] << component
        component
      end
      
      cleaned_override["min_gears"] = group_override["min_gears"] if group_override.has_key?("min_gears")
      cleaned_override["max_gears"] = group_override["max_gears"] if group_override.has_key?("max_gears")
      cleaned_override["additional_filesystem_gb"] = group_override["additional_filesystem_gb"] if group_override.has_key?("additional_filesystem_gb")
      cleaned_overrides << cleaned_override if group_override["components"] and group_override["components"].count > 0
    end

    # work on cleaned_overrides only 
    go_map = {}
    cleaned_overrides.each { |go|
      merged_go = deep_copy(go)
      go["components"].each { |comp|
        existing_go = go_map["#{comp["cart"]}/#{comp["comp"]}"]
        merged_go = merge_group_overrides(merged_go, existing_go) if existing_go
      }
      merged_go["components"].each { |comp|
        go_map["#{comp["cart"]}/#{comp["comp"]}"] = merged_go
      }
    }
    processed_group_overrides = []
    component_instances.each { |ci|
      go = go_map["#{ci["cart"]}/#{ci["comp"]}"]
      next if go.nil?
      processed_group_overrides << deep_copy(go) if !processed_group_overrides.include? go
    }
    # processed_group_overrides = deep_copy(go_map.values.uniq)
    return [processed_group_overrides, processed_group_overrides]
  end

  def merge_group_overrides(first, second)
    return_go = { }
    return_go["components"] = (first["components"] + second["components"]).uniq
    return_go["min_gears"] = [first["min_gears"]||1, second["min_gears"]||1].max if first["min_gears"] or second["min_gears"]
    return_go["additional_filesystem_gb"] = [first["additional_filesystem_gb"]||0, second["additional_filesystem_gb"]||0].max if first["additional_filesystem_gb"] or second["additional_filesystem_gb"]
    fmax = (first["max_gears"].nil? or first["max_gears"]==-1) ? 10000 : first["max_gears"]
    smax = (second["max_gears"].nil? or second["max_gears"]==-1) ? 10000 : second["max_gears"]
    return_go["max_gears"] = [fmax,smax].min if first["max_gears"] or second["max_gears"]
    return_go["max_gears"] = -1 if return_go["max_gears"]==10000

    fi = GEAR_SIZES.index(first["gear_size"]) || 0
    si = GEAR_SIZES.index(second["gear_size"]) || 0
    return_go["gear_size"] = GEAR_SIZES[[fi,si].max] if first["gear_size"] or second["gear_size"]
    return_go
  end

  # Computes the group instances, component instances and connections required to support a given set of features
  #
  # == Parameters:
  # feature::
  #   A list of features
  # group_overrides::
  #   A list of group-overrides which specify which components must be placed on the same group.
  #   Components can be specified as Hash{cart: <cart name> [, comp: <component name>]}
  #
  # == Returns:
  # connections::
  #   An array of connections
  # group instances::
  #   An array of hash values representing a group instances.
  def elaborate(features, group_overrides = [])
    profiles = []
    added_cartridges = []
    overrides = deep_copy(group_overrides)

    #calculate initial list based on user provided dependencies
    features.each do |feature|
      cart = CartridgeCache.find_cartridge(feature)
      raise OpenShift::UnfulfilledRequirementException.new(feature) if cart.nil?
      prof = cart.profile_for_feature(feature)
      added_cartridges << cart
      profiles << {cartridge: cart, profile: prof}
    end

    #solve for transitive dependencies
    until added_cartridges.length == 0 do
      carts_to_process = added_cartridges
      added_cartridges = []
      carts_to_process.each do |cart|
        cart.requires.each do |feature|
          next if profiles.count{|d| d[:cartridge].features.include?(feature)} > 0

          cart = CartridgeCache.find_cartridge(feature)
          raise OpenShift::UnfulfilledRequirementException.new(feature) if cart.nil?
          prof = cart.profile_for_feature(feature)
          added_cartridges << cart
          profiles << {cartridge: cart, profile: prof}
        end
      end
    end

    #calculate component instances
    component_instances = []
    profiles.each do |data|
      data[:profile].components.each do |component|
        component_instances << {
          cartridge: data[:cartridge],
          component: component
        }
      end
    end

    #calculate connections
    publishers = {}
    connections = []
    component_instances.each do |ci|
      ci[:component].publishes.each do |connector|
        type = connector.type
        name = connector.name
        publishers[type] = [] if publishers[type].nil?
        publishers[type] << { cartridge: ci[:cartridge].name , component: ci[:component].name, connector: name }
      end
    end

    component_instances.each do |ci|
      ci[:component].subscribes.each do |connector|
        stype = connector.type
        sname = connector.name

        if publishers.has_key? stype
          publishers[stype].each do |cinfo|
            connections << {
              "from_comp_inst" => {"cart"=> cinfo[:cartridge], "comp"=> cinfo[:component]},
              "to_comp_inst" =>   {"cart"=> ci[:cartridge].name, "comp"=> ci[:component].name},
              "from_connector_name" => cinfo[:connector],
              "to_connector_name" =>   sname,
              "connection_type" =>     stype}
            if stype.starts_with?("FILESYSTEM") or stype.starts_with?("SHMEM")
              overrides << [{"cart"=> cinfo[:cartridge], "comp"=> cinfo[:component]}, {"cart"=> ci[:cartridge].name, "comp"=> ci[:component].name}]
            end
          end
        end
      end
    end
    
    comp_specs = component_instances.map{ |ci| {"comp"=> ci[:component].name, "cart"=> ci[:cartridge].name}}
    processed_overrides, cleaned_overrides = process_group_overrides(comp_specs, overrides)
    group_instances = processed_overrides.map{ |go| 
      group_instance = {}
      group_instance[:component_instances] = go["components"]
      group_instance[:scale] = {}
      group_instance[:scale][:min] = ( go["min_gears"] || 1 )
      group_instance[:scale][:max] = ( go["max_gears"] || -1 )
      group_instance[:scale][:gear_size] = ( go["gear_size"] || GEAR_SIZES[0] )
      group_instance[:scale][:additional_filesystem_gb] ||= 0
      group_instance[:scale][:additional_filesystem_gb] += (go["additional_filesystem_gb"] || 0)
      group_instance[:_id] =Moped::BSON::ObjectId.new
      group_instance
    }
    [connections, group_instances, cleaned_overrides]
  end

  # Returns the configure order specified in the application descriptor or processes the configure
  # orders for each component and returns the final order (topological sort).
  # @note This is calculates seperately from start/stop order as this function is usually used to
  #   compute the {PendingAppOps} while start/stop order applies to already configured components.
  #
  # == Parameters:
  # comp_specs::
  #   Array of components specs to order.
  #
  # == Returns:
  # {ComponentInstance} objects ordered by calculated configure order
  def calculate_configure_order(comp_specs)
    configure_order = ComponentOrder.new
    comps = []
    categories = {}

    comp_specs.each do |comp_inst|
      cart = CartridgeCache.find_cartridge(comp_inst["cart"])
      prof = cart.get_profile_for_component(comp_inst["comp"])

      comps << {cart: cart, prof: prof}
      [[comp_inst["cart"]],cart.categories,cart.provides,prof.provides].flatten.each do |cat|
        categories[cat] = [] if categories[cat].nil?
        categories[cat] << comp_inst
      end
      configure_order.add_component_order([comp_inst])
    end

    #use the map to build DAG for order calculation
    comps.each do |comp_spec|
      configure_order.add_component_order(comp_spec[:prof].configure_order.map{|c| categories[c]}.flatten)
    end

    #calculate configure order using tsort
    if self.component_configure_order.empty?
      computed_configure_order = configure_order.tsort
    else
      computed_configure_order = self.component_configure_order.map{|c| categories[c]}.flatten
    end
    
    # configure order can have nil if the component is already configured
    # for eg, phpmyadmin is being added and it is the only component being passed/added
    # this could happen if mysql is already previously configured
    computed_configure_order.select { |co| not co.nil? }
  end

  # Returns the start/stop order specified in the application descriptor or processes the start and stop
  # orders for each component and returns the final order (topological sort).
  #
  # == Returns:
  # start_order::
  #   {ComponentInstance} objects ordered by calculated start order
  # stop_order::
  #   {ComponentInstance} objects ordered by calculated stop order
  def calculate_component_orders
    start_order = ComponentOrder.new
    stop_order = ComponentOrder.new
    comps = []
    categories = {}

    #build a map of [categories, features, cart name] => component_instance
    component_instances.each do |comp_inst|
      cart = CartridgeCache.find_cartridge(comp_inst.cartridge_name)
      prof = cart.get_profile_for_component(comp_inst.component_name)

      comps << {cart: cart, prof: prof}
      [[comp_inst.cartridge_name],cart.categories,cart.provides,prof.provides].flatten.each do |cat|
        categories[cat] = [] if categories[cat].nil?
        categories[cat] << comp_inst
      end
      start_order.add_component_order([comp_inst])
      stop_order.add_component_order([comp_inst])
    end

    #use the map to build DAG for order calculation
    comps.each do |comp_spec|
      start_order.add_component_order(comp_spec[:prof].start_order.map{|c| categories[c]}.flatten)
      stop_order.add_component_order(comp_spec[:prof].stop_order.map{|c| categories[c]}.flatten)
    end

    #calculate start order using tsort
    if self.component_start_order.empty?
      computed_start_order = start_order.tsort
    else
      computed_start_order = self.component_start_order.map{|c| categories[c]}.flatten
    end

    #calculate stop order using tsort
    if self.component_stop_order.empty?
      computed_stop_order = stop_order.tsort
    else
      computed_stop_order = self.component_stop_order.map{|c| categories[c]}.flatten
    end

    # start/stop order can have nil if the component is not present in the application
    # for eg, php is being stopped and haproxy is not present in a non-scalable application
    computed_start_order = computed_start_order.select { |co| not co.nil? }
    computed_stop_order = computed_stop_order.select { |co| not co.nil? }

    [computed_start_order, computed_stop_order]
  end

  # Gets a feature name for the cartridge/component combination
  #
  # == Parameters:
  # cartridge_name::
  #   Name of cartridge
  # component_name::
  #   Name of component
  #
  # == Returns:
  # Feature name provided by the cartridge that includes the component
  def get_feature(cartridge_name,component_name)
    cart = CartridgeCache.find_cartridge cartridge_name
    prof = cart.get_profile_for_component component_name
    (prof.provides.length > 0 && prof.name != cart.default_profile) ? prof.provides.first : cart.provides.first
  end

  def get_components_for_feature(feature)
    cart = CartridgeCache.find_cartridge(feature)
    raise OpenShift::UserException.new("No cartridge found that provides #{feature}", 109) if cart.nil?
    prof = cart.profile_for_feature(feature)
    prof.components.map{ |comp| self.component_instances.find_by(cartridge_name: cart.name, component_name: comp.name) }
  end

  def gen_non_scalable_app_overrides(features)
    #find web_framework
    web_framework = {}
    features.each do |feature|
      cart = CartridgeCache.find_cartridge(feature)
      next unless cart.categories.include? "web_framework"
      prof = cart.profile_for_feature(feature)
      comp = prof.components.first
      web_framework = {"cart"=>cart.name, "comp"=>comp.name}
    end
    
    group_overrides = [{"components"=>[web_framework], "max_gears"=> 1}]
    #generate group overrides to colocate all components with web_framework and limit scale to 1
    features.each do |feature|
      cart = CartridgeCache.find_cartridge(feature)
      next if cart.categories.include? "web_framework"
      prof = cart.profile_for_feature(feature)
      components = prof.components
      group_overrides += components.map { |comp| 
        {
          "components" => [
            web_framework,
            {"cart"=>cart.name, "comp"=>comp.name}
          ],
          "max_gears" => 1
        }
      }
    end
    
    group_overrides
  end
  
  def get_updated_ssh_keys(user_id, keys_attrs)
    updated_keys_attrs = deep_copy(keys_attrs).map { |k|
      if user_id.nil?
        k["name"] = "domain-" + k["name"]
      else
        k["name"] = user_id.to_s + "-" + k["name"]
      end
      k
    }
    updated_keys_attrs
  end
  
  # Get path for checking application health
  # This method is only to maintain backwards compatibility for rest api version 1.0
  # @return [String]
  def health_check_path
    web_cart = get_framework_cartridge
    if web_cart.nil?
      page = 'health'
    elsif web_cart.categories.include? 'php'
      page = 'health_check.php'
    elsif web_cart.categories.include? 'zend'
      page = 'health_check.php'
    elsif web_cart.categories.include? 'perl'
      page = 'health_check.pl'
    else
      page = 'health'
    end
  end
  
  # Get scaling limits for the application's group instance that has the web framework cartridge
  # This method is only to maintain backwards compatibility for rest api version 1.0
  # @return [Integer, Integer]
  def get_app_scaling_limits
    web_cart = get_framework_cartridge
    component_instance = self.component_instances.find_by(cartridge_name: web_cart.name)
    group_instance = group_instances_with_scale.select{ |go| go.all_component_instances.include? component_instance }[0]
    [group_instance.min, group_instance.max]
  end
  
  # Get the web framework cartridge
  # This method is only to maintain backwards compatibility for rest api version 1.0
  # @return Cartridge
  def get_framework_cartridge
    web_cart = nil
    self.requires.each do |feature|
      cart = CartridgeCache.find_cartridge(feature)
      next unless cart.categories.include? "web_framework"
      web_cart = cart
      break
    end
    web_cart
  end  
end
