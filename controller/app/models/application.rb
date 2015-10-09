require 'matrix'

class Matrix
  def []=(i, j, x)
    @rows[i][j] = x
  end
end

##
# @api model
# Class to represent an OpenShift Application
# @!attribute [r] name
#   @return [String] The name of the application. The name of the application is user provided and can be mixed case
# @!attribute [r] canonical_name
#   @return [String] The down-cased name of the application
# @!attribute [r] uuid
#   @return [String] UUID that represents this application. This is usually the same as the MongoID ID field.
#     For applications that existed before the transition to MongoID, this field represents the original UUID and will differ
#     from the MongoID ID field.
# @!attribute [rw] domain_requires
#   @return [Array<String>] Array of IDs of the applications that this application is dependent on
#     If the parent application is destroyed, this application also needs to be destroyed
# @!attribute [rw] group_overrides
#   @return [Array<Array<String>>] Array of Array of components that need to be co-located
# @!attribute [rw] pending_op_groups
#   @return [Array<PendingAppOpGroup>] List of pending operations to be performed on this application
# @!attribute [r] domain
#   @return [Domain] Domain that this application is part of.
# @!attribute [rw] component_stop_order
#   @return [Array<String>] Normally configure order computed based on order specified by each component's manifest.
#     This attribute is used to overrides the configure order
# @!attribute [r] default_gear_size
#   @return [String] The default gear size to use when creating a new {GroupInstance}. This value can be overridden
#     using group overrides or in the cartridge manifest
# @!attribute [r] scalable
#   @return [Boolean] This value is true if the application is scalable
# @!attribute [r] init_git_url
#   @return [String] Stores the URL to the GIT url specified during application creation
# @!attribute [r] analytics
#   @return [Hash] Location to store analytics data relevant to the application
# @!attribute [r] component_instances
#   @return [Array<ComponentInstance>] Array of components in this application
# @!attribute [r] group_instances
#   @return [Array<GroupInstance>] Array of gear groups in the application
# @!attribute [r] app_ssh_keys
#   @return [Array<ApplicationSshKey>] Array of auto-generated SSH keys used by components of the application to connect to other gears
# @!attribute [r] aliases
#   @return [Array<String>] Array of DNS aliases registered with this application.
#     @see {Application#add_alias} and {Application#remove_alias}
# @!attribute [r] deployments
#   @return [Array<Deployment>] Array of deployment for this application
class Application
  include Mongoid::Document
  include Mongoid::Timestamps
  include MongoidAtomicUpdate
  include Membership

  # Maximum length of  a valid application name
  APP_NAME_MAX_LENGTH = 32

  # Numeric representation for unlimited scaling
  MAX_SCALE = -1
  MAX_SCALE_NUM = 1000000

  # Maximum dependency chain length can be resolved during elaborate()
  MAX_CARTRIDGE_RECURSION = 5

  # Available deployment types
  DEPLOYMENT_TYPES = ['git', 'binary']

  # This is the current regex for validations for new applications
  APP_NAME_REGEX = /\A[A-Za-z0-9]*\z/
  def self.check_name!(name)
    if name.blank? or name !~ APP_NAME_REGEX
      raise Mongoid::Errors::DocumentNotFound.new(Application, nil, [name])
    end
    name
  end

  field :name, type: String
  field :canonical_name, type: String
  field :group_overrides, type: TypedArray[GroupOverride], default: []
  embeds_many :pending_op_groups, class_name: PendingAppOpGroup.name, cascade_callbacks: true

  belongs_to :domain, inverse_of: :applications
  field :domain_namespace, type: String # denormalized canonical namespace
  belongs_to :owner, class_name: CloudUser.name, inverse_of: :owned_applications
  belongs_to :builder, class_name: Application.name, inverse_of: :built_applications
  has_many :built_applications, class_name: Application.name

  field :downloaded_cart_map, type: Hash # REMOVED, pending migration
  field :default_gear_size, type: String, default: Rails.configuration.openshift[:default_gear_size]
  field :scalable, type: Boolean, default: false
  field :ha, type: Boolean, default: false
  field :init_git_url, type: String, default: ""
  field :analytics, type: Hash, default: {}
  field :secret_token, type: String
  field :config, type: Hash, default: {'auto_deploy' => true, 'deployment_branch' => 'master', 'keep_deployments' => 1, 'deployment_type' => 'git'}
  field :meta, type: Hash

  embeds_many :component_instances, class_name: ComponentInstance.name, cascade_callbacks: true
  embeds_many :group_instances, class_name: GroupInstance.name
  embeds_many :gears, class_name: Gear.name
  embeds_many :app_ssh_keys, class_name: ApplicationSshKey.name
  embeds_many :aliases, class_name: Alias.name
  embeds_many :deployments, class_name: Deployment.name

  has_members through: :domain, default_role: :admin

  validates :config, presence: true, application_config: true
  validates :meta, application_metadata: true

  validates :name,
    presence: {message: "Application name is required and cannot be blank."},
    format:   {with: APP_NAME_REGEX, message: "Application name must contain only alphanumeric characters (a-z, A-Z, or 0-9)."},
    length:   {maximum: APP_NAME_MAX_LENGTH, minimum: 0, message: "Application name must be a minimum of 1 and maximum of #{APP_NAME_MAX_LENGTH} characters."}
  validate :extended_validator
  validate :name_plus_domain

  # Returns a map of field to error code for validation failures
  # * 105: Invalid application name
  def self.validation_map
    {name: 105}
  end

  index({'gears.uuid' => 1}, {:unique => true, :sparse => true})
  index({'component_instances.cartridge_id' => 1}, {:sparse => true})
  index({'pending_op_groups.created_at' => 1})
  index({'domain_id' => 1, 'canonical_name' => 1}, {:unique => true})
  create_indexes

  # non-persisted field used to store user agent of current request
  attr_accessor :user_agent
  attr_accessor :connections
  attr_accessor :region_id
  #
  # Return a count of the gears for each application identified by the current query.  Returns
  # an array of hashes including:
  #
  #   '_id': application id
  #   'domain_id': domain id
  #   'gear_sizes': hash of gear size strings to counts
  #
  def self.with_gear_counts(domains=queryable)
    apps_info = []
    Application.in(domain_id: domains.map(&:_id)).each do |app|
      gear_sizes = {}
      app.group_instances.each do |gi|
        gear_sz = gi.gear_size
        gear_sizes[gear_sz] ||= 0
        gear_sizes[gear_sz] += gi.gears.length if gi.gears.present?
      end if app.group_instances.present?
      apps_info << {"_id" => app._id, "domain_id" => app.domain_id, "gear_sizes" => gear_sizes}
    end
    apps_info
  end

  # Denormalize the domain namespace and the owner id, ensure the init_git_url is clean
  before_save prepend: true do
    if has_domain?
      self.domain_namespace = domain.canonical_namespace if domain_namespace.blank? || domain_id_changed?
      self.owner_id = domain.owner_id if owner_id.blank? || domain_id_changed?
    end
    if init_git_url_changed?
      self.init_git_url = OpenShift::Git.persistable_clone_spec(init_git_url)
    end
  end

  # Hook to prevent accidental deletion of MongoID model before all related {Gear}s are removed
  before_destroy do |app|
    raise "Please call destroy_app to delete all gears before deleting this application" if gears.count > 0
  end

  # Observer hook for extending the validation of the application in an ActiveRecord::Observer
  # @see http://api.rubyonrails.org/classes/ActiveRecord/Observer.html
  def extended_validator
    notify_observers(:validate_application)
  end

  def name_plus_domain
    return if persisted? # only check at creation - old apps are grandfathered
    charlimit = Rails.application.config.openshift[:limit_app_name_chars]
    if charlimit > 0 && (name + domain.namespace).length > charlimit
      errors.add :name,
        "Name '#{name}' and domain namespace '#{domain.namespace}' cannot add up to more than #{charlimit} characters."
    end
  end
  ##
  # Helper for test cases to create the {Application}
  #
  # @param application_name [String] Name of the application
  # @param cartridges [Array<CartridgeInstance>] List of cartridge instances to add to the application
  # @param domain [Domain] The domain namespace under which this application is created
  # @param opts [Hash] Flexible array of optional parameters
  #   default_gear_size [String] The default gear size to use when creating a new {Gear} for the application
  #   scalable [Boolean] Indicates if the application should be scalable or host all cartridges on a single gear.
  #      If set to true, a "web_proxy" cartridge is automatically added to perform load-balancing for the web tier
  #   available [Boolean] Indicates if the application should be be highly available.  Implies 'scalable'
  #   result_io [ResultIO, #output] Object to log all messages and cartridge output
  #   initial_git_url [String] URL to git repository to retrieve application code
  #   user_agent [String] user agent string of browser used for this rest API request
  #   builder_id [String] the identifier of the application that is using this app as a builder
  #   user_env_vars [Array<Hash>] array of environment variables to add to this application
  # @return [Application] Application object that has been created
  # @raise [OpenShift::ApplicationValidationException] Exception to indicate a validation error
  def self.create_app(application_name, cartridges, domain, opts=nil)
    opts ||= {}

    app = Application.new(
      domain: domain,
      name: application_name,
      default_gear_size: opts[:default_gear_size].presence || Rails.application.config.openshift[:default_gear_size],
      scalable: opts[:scalable] || opts[:available],
      ha: opts[:available],
      builder_id: opts[:builder_id],
      user_agent: opts[:user_agent],
      init_git_url: opts[:initial_git_url]
    )
    app.config.each do |k, default|
      v = opts[k.to_sym]
      app.config[k] = v unless v.nil?
    end
    app.analytics['user_agent'] = opts[:user_agent]

    io = opts[:result_io] || ResultIO.new
    io.append app.add_initial_cartridges(cartridges, opts[:initial_git_url], opts[:user_env_vars])
    app
  end

  ##
  # Helper method to find an application using the application name
  # @param user [CloudUser] The owner of the application
  # @param app_name [String] The application name
  # @return [Application, nil] The application object or nil if no application matches
  #
  def self.find_by_user(user, app_name)
    Application.in(domain: user.domains.map(&:_id)).where(canonical_name: app_name.downcase).first
  end

  ##
  # Helper method to find an application that runs on a particular gear
  # @param gear_uuid [String] The UUID of the gear
  # @return [[Application,Gear]] The application and gear objects or nil array if no application matches
  def self.find_by_gear_uuid(gear_uuid)
    obj_id = gear_uuid.to_s
    app = Application.where("gears.uuid" => obj_id).first
    return [nil, nil] if app.nil?
    gear = app.gears.select { |g| g.uuid == obj_id }.first
    return [app, gear]
  end

  ##
  # Constructor. Should not be used directly. Use {Application#create_app} instead.
  def initialize(attrs = nil, options = nil)
    super
    self.app_ssh_keys = []
    self.analytics ||= {}

    # the resultant string length is 4/3 times the number specified as the first argument
    # with 96 specified, the token is going to be 128 characters long
    self.secret_token = SecureRandom.urlsafe_base64(96, false)
  end

  def uuid
    _id.to_s
  end

  ##
  # Setter for application name. Sets both the name and the canonical_name for the application
  # @param app_name [String] The application name
  def name=(app_name)
    self.canonical_name = app_name.downcase
    super
  end

  ##
  # Return either the denormalized domain name or nil, since namespace is denormalized
  def domain_namespace
    attributes['domain_namespace'] or has_domain? ? domain.canonical_namespace : nil
  end

  def capabilities
    @capabilities ||= domain.owner.capabilities.deep_dup rescue (raise OpenShift::UserException, "The application cannot be changed at this time.  Contact support.")
  end

  def quarantined
    gears.any?(&:quarantined)
  end

  # def group_overrides=(other)
  #   other = GroupOverride::Array.new.concat(other) if other && !other.is_a?(GroupOverride::Array)
  #   super(other)
  # end

  ##
  # Enumerates all the Cartridges that are installed in this application.  If
  # pending is true the op group will be iterated to check for changes to the
  # list - if pending is set to an op group all earlier op groups will be iterated.
  #
  # In general, this is the primary mechanism by which the cartridges in the
  # application should be queried.
  #
  def cartridges(pending=false, &block)
    # For efficiency, generate different enumerators
    e = if pending
      EnumeratorArray.new do |y|
        removed = []
        pending = pending_op_groups.last
        pending_op_groups.reverse_each do |g|
          # skip until we find the passed group
          if pending
            next unless pending.equal?(g)
            pending = nil
          end
          case g
          when AddFeaturesOpGroup
            g.cartridges.each do |c|
              next if removed.any?{ |r| r.removes?(c) }
              y << c
            end
          when RemoveFeaturesOpGroup
            (removed ||= []) << g
          end
        end
        component_instances.each do |i|
          next if removed.any?{ |r| r.removes?(i.cartridge) }
          y << i.cartridge
        end
      end
    else
      EnumeratorArray.new do |y|
        component_instances.each do |i|
          y << i.cartridge
        end
      end
    end
    return e.each(&block) if block_given?
    e
  end

  ##
  # Return all of the existing downloaded cartridges in this app.
  #
  def downloaded_cartridges
    cartridges.select(&:singleton?)
  end

  ##
  # Get the web framework cartridge or nil if it doesn't exist.
  # This method is only to maintain backwards compatibility for rest api version 1.0
  # @return Cartridge
  def web_cartridge
    cartridges(true).find(&:is_web_framework?)
  end

  ##
  # Return the first web framework component in this application.
  #
  def web_component_instance
    component_instances.detect(&:is_web_framework?)
  end

  ##
  # Adds the given ssh key to the application.
  # @param user_id [String] The ID of the user associated with the keys. If the user ID is nil, then the key is assumed to be a system generated key
  # @param keys [Array<SshKey>] Array of keys to add to the application.
  # @param parent_op [PendingDomainOps] object used to track this operation at a domain level
  # @return [ResultIO] Output from cartridges
  def add_ssh_keys(keys, parent_op=nil)
    return if keys.empty?
    #check user access before adding key
    add_keys = []
    keys.flatten.each do |key|
      add_keys.push(key) unless key.class == UserSshKey and key.cloud_user and !Ability.has_permission?(key.cloud_user._id, :ssh_to_gears, Application, role_for(key.cloud_user._id), self)
    end
    keys_attrs = get_updated_ssh_keys(add_keys)
    Lock.run_in_app_lock(self) do
      op_group = UpdateAppConfigOpGroup.new(add_keys_attrs: keys_attrs, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups.push op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # Remove the given ssh key from the application. If multiple users share the same key, only the specified users key is removed
  # but application access will still be possible.
  # @param keys [Array<SshKey>] Array of keys to remove from the application.
  # @param parent_op [PendingDomainOps] object used to track this operation at a domain level
  # @return [ResultIO] Output from cartridges
  def remove_ssh_keys(keys, parent_op=nil)
    return if keys.empty?
    keys_attrs = get_updated_ssh_keys(keys)
    Lock.run_in_app_lock(self) do
      op_group = UpdateAppConfigOpGroup.new(remove_keys_attrs: keys_attrs, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # Updates the configuration of the application.
  # @return [ResultIO] Output from cartridges
  def update_configuration(new_config={})
    # set the new config in the application object without persisting for validation
    self.config['auto_deploy'] = new_config['auto_deploy'] unless new_config['auto_deploy'].nil?
    self.config['deployment_branch'] = new_config['deployment_branch'] unless new_config['deployment_branch'].nil?
    self.config['keep_deployments'] = new_config['keep_deployments'] unless new_config['keep_deployments'].nil?
    self.config['deployment_type'] = new_config['deployment_type'] unless new_config['deployment_type'].nil?

    if self.invalid?
      messages = []
      if self.errors.messages[:config]
        self.errors.messages[:config].each do |error|
          messages.push(error[:message]) if error[:message]
        end
      else
        self.errors.messages.each do |key, value|
          messages.push("#{key} #{value.join(",")}")
        end
      end
      raise OpenShift::UserException.new("Invalid application configuration: #{messages}", 1)
    end

    Lock.run_in_app_lock(self) do
      # set the config parameters not specified in new_config based on the updates values in the application
      ['auto_deploy', 'deployment_branch', 'keep_deployments', 'deployment_type'].each {|k| new_config[k] = self.config[k] if new_config[k].nil?}
      op_group = UpdateAppConfigOpGroup.new(config: new_config)
      op_group.set_created_at
      app_updates = {"$push" => { pending_op_groups: op_group.as_document }, "$set" => {}}
      new_config.keys.each { |k| app_updates["$set"]["config.#{k}"] = new_config[k] unless new_config[k].nil? }

      # do an atomic update and reload the application
      Application.where(_id: self._id).update(app_updates)
      self.reload

      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # Removes all ssh keys from the application's gears and adds the given ssh keys.
  # @param user_id [String] The ID of the user associated with the keys. If the user ID is nil, then the key is assumed to be a system generated key
  # @param keys [Array<SshKey>] Array of keys to add to the application.
  # @return [ResultIO] Output from cartridges
  def fix_gear_ssh_keys
    Lock.run_in_app_lock(self) do
      op_group = ReplaceAllSshKeysOpGroup.new(keys_attrs: self.get_all_updated_ssh_keys, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # Adds environment variables to all gears on the application.
  # @param vars [Array<Hash>] List of environment variables. Each entry must contain key and value
  # @param parent_op [PendingDomainOps] object used to track this operation at a domain level
  # @return [ResultIO] Output from cartridges
  def add_env_variables(vars, parent_op=nil)
    Lock.run_in_app_lock(self) do
      op_group = UpdateAppConfigOpGroup.new(add_env_vars: vars, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # Remove environment variables from all gears on the application.
  # @param vars [Array<Hash>] List of environment variables. Each entry must contain key and value
  # @param parent_op [PendingDomainOps] object used to track this operation at a domain level
  # @return [ResultIO] Output from cartridges
  def remove_env_variables(vars, parent_op=nil)
    Lock.run_in_app_lock(self) do
      op_group = UpdateAppConfigOpGroup.new(remove_env_vars: vars, parent_op: parent_op, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # Add or Update or Delete user defined environment variables to all gears on the application.
  # @param vars [Array<Hash>] User environment variables. Each entry contains name and/or value
  # @return [ResultIO] Output from node platform
  def patch_user_env_variables(vars)
    Lock.run_in_app_lock(self) do
      op_group = PatchUserEnvVarsOpGroup.new(user_env_vars: vars, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # List all or selected user defined environment variables in the application.
  # @param vars [Array<String>] Selected user environment variable names. Each entry must contain name
  # @return [Hash] Environment variables in the application.
  def list_user_env_variables(vars=[])
    result_io = get_app_dns_gear.list_user_env_vars(vars)
    JSON.parse(result_io.resultIO.string)
  end

  ##
  # Return an array of all of the application overrides defined by the application itself (stored on
  # the model or implied by the scalable and ha flags).
  #
  # By passing "specs" you will retrieve the overrides for the application as if the application were
  # changing.
  #
  # The array returned is a copy of the core data and can be changed without editing the application.
  #
  def implicit_application_overrides(specs=nil)
    specs ||= component_instances.map(&:to_component_spec)

    # Overrides from the basic cartridge definitions.
    overrides = []

    specs.each do |spec|
      # Cartridges can contribute overrides
      spec.cartridge.group_overrides.each do |override|
        if o = GroupOverride.resolve_from(specs, override)
          overrides << o.implicit
        end
      end

      # Each component has an implicit override based on its scaling
      comp = spec.component
      overrides <<
          if comp.is_sparse?
            GroupOverride.new([spec]).implicit
          elsif spec.cartridge.is_external?
            GroupOverride.new([spec], 0, 0).implicit
          else
            GroupOverride.new([spec], comp.scaling.min, comp.scaling.max).implicit
          end
    end

    # Overrides that are implicit to applications of this type
    if self.scalable
      if self.ha
        overrides.concat(implicit_available_overrides(specs))
      end
    else
      overrides.concat(implicit_non_scalable_overrides(specs))
    end

    overrides
  end

  ##
  # An available application has an implicit override to have 2 minimum web gears,
  # and 2 sparse web proxy components on those gears.
  #
  def implicit_available_overrides(specs)
    overrides = []

    # make the web framework min scale 2
    if primary = specs.find{ |i| i.cartridge.is_web_framework? } || specs.find{ |i| i.cartridge.is_service? }
      overrides << GroupOverride.new([primary.dup], 2).implicit
    end

    # ensure the proxy has the appropriate min scale and multiplier
    if proxy = specs.find{ |i| i.cartridge.is_web_proxy? }
      overrides << GroupOverride.new([ComponentOverrideSpec.new(proxy.dup, 2, -1, Rails.configuration.openshift[:default_ha_multiplier] || 0).merge(proxy)]).implicit
    end
    overrides
  end

  ##
  # A non-scalable application has an implicit override for all components to be
  # located on the same gear.
  #
  def implicit_non_scalable_overrides(specs)
    [GroupOverride.new(specs.select{ |i| not i.cartridge.is_external? }, nil, 1).implicit]
  end

  ##
  # Return the full list of overrides, implicit and explicit,
  # defined on this application.  These overrides are mutable.
  #
  # If specs is passed, only the override rules that apply
  # to that new list of specs (components) will be returned.
  #
  def application_overrides(specs=nil)
    specs ||= component_instances.map(&:to_component_spec)

    overrides = implicit_application_overrides(specs)

    # Overrides from the persisted application
    group_overrides.each do |override|
      if o = GroupOverride.resolve_from(specs, override)
        overrides << o
      end
    end

    split_platform_overrides(overrides)
  end

  ##
  # Return one override for each group instance, containing the effective rules
  # for that instance.  The instance member points to the group_instance that
  # controls the override.  All rules should be populated.
  #
  def group_instances_with_overrides
    GroupOverride.reduce_to(group_instance_overrides, application_overrides).each do |o|
      o.defaults(1, -1, self.default_gear_size, 0)
    end
  end

  def validate_cartridge_instances!(cartridges)
    if not cartridges.all?(&:valid?)
      cartridges.each{ |c| c.errors.full_messages.uniq.each{ |m| errors[:cartridge] = m } }
      raise OpenShift::ApplicationValidationException.new(self)
    end

    if !Rails.configuration.openshift[:allow_obsolete_cartridges] && (obsolete = cartridges.select(&:is_obsolete?).presence) && (self.persisted? || !self.builder_id)
      obsolete.each{ |c| self.errors[:cartridge] = "The cartridge '#{c.name}' is no longer available to be added to an application." }
      raise OpenShift::ApplicationValidationException.new(self)
    end

    true
  end

  def find_component_instance_for(spec)
    component_instances.detect{ |i| i.matches_spec?(spec) }.tap{ |instance| spec.application = self if instance } or
      raise Mongoid::Errors::DocumentNotFound.new(ComponentInstance, spec.mongoize)
  end

  ##
  # Perform common initial setup of an application, including persisting it and cleanup
  # if the creation fails.
  #
  # @param cartridges [Array<CartridgeInstance>] List of cartridge instances to add to the application
  # @param init_git_url [String] URL to git repository to retrieve application code
  # @param user_env_vars [Array<Hash>] array of environment variables to add to this application
  # @return [ResultIO] Output from cartridges
  # @raise [OpenShift::ApplicationValidationException] Exception to indicate a validation error
  def add_initial_cartridges(cartridges, init_git_url=nil, user_env_vars=nil)

    if self.scalable and not cartridges.any?(&:is_web_proxy?)
      cartridges << CartridgeInstance.new(CartridgeCache.find_cartridge_by_feature('web_proxy'))
    end

    group_overrides = CartridgeInstance.overrides_for(cartridges, self)
    self.validate_cartridge_instances!(cartridges)

    # supply initial app template if configured in broker conf
    template_for = Rails.application.config.openshift[:app_template_for]
    init_git_url ||= cartridges.select(&:is_web_framework?).
                     map {|c| template_for[c.name] || template_for[c.short_name] }.
                     compact.first
    add_cartridges(cartridges.map(&:cartridge), group_overrides, init_git_url, user_env_vars)

  rescue => e
    self.delete if persisted? && !(group_instances.present? || component_instances.present?)
    raise e
  end

  ##
  # Adds components to the application
  # @param cartridges [Array<Cartridge>] List of cartridges to add to the application. Each cartridge must be resolved prior to this call
  # @param group_overrides [Array] List of group overrides
  # @param init_git_url [String] URL to git repository to retrieve application code
  # @return [ResultIO] Output from cartridges
  # @raise [OpenShift::UserException] Exception raised if there is any reason the cartridge cannot be added into the Application
  def add_cartridges(cartridges, group_overrides=[], init_git_url=nil, user_env_vars=nil, io=ResultIO.new)
    ssl_endpoint = Rails.application.config.openshift[:ssl_endpoint]
    cart_name_map = {}

    all = self.cartridges + cartridges
    dependencies = add_required_dependencies(self.cartridges + cartridges) - all
    if dependencies.present?
      Rails.logger.debug("Adding dependencies #{dependencies.map(&:name).to_sentence} to requested #{cartridges.map(&:name).to_sentence}")
      cartridges += dependencies
    end

    cartridges.each do |cart|
      # ensure that the user isn't trying to add multiple versions of the same cartridge
      if cart_name_map.has_key?(cart.original_name)
        raise OpenShift::UserException.new("#{cart.name} cannot co-exist with #{cart_name_map[cart.original_name]} in the same application", 136, "cartridge")
      else
        cart_name_map[cart.original_name] = cart.name
      end

      if cart.components.length != 1
        raise OpenShift::UserException.new("The cartridge #{cart.name} is invalid: only one component may be defined per cartridge.", 136, "cartridge")
      end

      # check if the requested cartridge is already in the application
      component_instances.each do |ci|
        ci_cart = ci.get_cartridge
        if ci_cart.original_name == cart.original_name
          if ci_cart.name == cart.name
            raise OpenShift::UserException.new("#{cart.name} already exists in your application", 136, "cartridge")
          else
            raise OpenShift::UserException.new("#{cart.name} cannot co-exist with cartridge #{ci.cartridge_name} in your application", 136, "cartridge")
          end
        end
      end

      if cart.is_web_framework? and defined?(cart.endpoints) and cart.endpoints.respond_to?(:each)
        cart_req_ssl_endpoint = false
        cart.endpoints.each do |endpoint|
          if endpoint.options and endpoint.options["ssl_to_gear"]
            cart_req_ssl_endpoint = true
          end
        end
        if (((ssl_endpoint == "deny") and cart_req_ssl_endpoint ) or
            ((ssl_endpoint == "force") and not cart_req_ssl_endpoint))
          raise OpenShift::UserException.new("Invalid cartridge '#{cart.name}' conflicts with platform SSL_ENDPOINT setting.", 109, "cartridge")
        end
      end

      # Validate that we are not trying to create a non-scalable app with carts that need to be scalable
      if cart.scaling_required? && !self.scalable
        raise OpenShift::UserException.new("#{cart.name} must be embedded in a scalable app.", 109)
      end

      # Validate that the cartridges support scalable if necessary
      if self.scalable && !(cart.is_plugin? || cart.is_service? || cart.is_web_framework? || cart.is_external?)
        raise OpenShift::UserException.new("#{cart.name} cannot be embedded in scalable app '#{name}'.", 109, 'cartridge')
      end

      # prevent a proxy from being added to a non-scalable (single-gear) application
      if cart.is_web_proxy? and !self.scalable
        raise OpenShift::UserException.new("#{cart.name} cannot be added to existing applications. It is automatically added when you create a scaling application.", 137, 'cartridge')
      end

      if self.scalable and cart.is_web_framework?
        cart_scalable = false
        cart.components.each do |component|
           next if component.scaling.min==1 and component.scaling.max==1
           cart_scalable = true
        end
        if !cart_scalable
          raise OpenShift::UserException.new("The cartridge '#{cart.name}' does not support being made scalable.", 109, 'scalable')
        end
      end

      # check if a cartridge with a min gear requirement of 2+ is being added to a non-scalable application
      if !self.scalable
        min_gears = 1
        cart.components.each do |component|
          min_gears = [min_gears, component.scaling.min].max
          raise OpenShift::UserException.new("The cartridge '#{cart.name}' requies a minimum of #{min_gears} gears and cannot be added to a non-scalable application.", 109, 'scalable') if min_gears > 1
        end
      end

      # Validate that this feature either does not have the domain_scope category
      # or if it does, then no other application within the domain has this feature already
      if cart.is_domain_scoped?
        if Application.where(domain_id: self.domain._id, "component_instances.cartridge_name" => cart.name).present?
          raise OpenShift::UserException.new("An application with #{cart.name} already exists within the domain. You can only have a single application with #{cart.name} within a domain.", 109, 'cartridge')
        end
      end

      # if there are any downloaded cartridges, validate their manifest
      if cart.manifest_url.present? and cart.manifest_text.present?
        begin
          OpenShift::Runtime::Manifest.new(cart.manifest_text).validate_categories
        rescue Exception => ex
          # we are raising a UserException in case of manifest validation failure
          raise OpenShift::UserException.new("The provided downloadable cartridge '#{cart.manifest_url}' cannot be loaded: #{ex.message}", 109, 'cartridge')
        end
      end
    end

    # validate the group overrides for the cartridges being added
    # combine the existing carts with the ones being added to get the full proposed group overrides
    specs = component_specs_from(cartridges) + self.component_instances.map(&:to_component_spec)
    specs.each do |spec|
      spec.cartridge.group_overrides.each do |override|
        if o = GroupOverride.resolve_from(specs, override)
          scalable_carts = []
          o.components.each do |component|
            cart = CartridgeCache.find_cartridge(component.cartridge_name, self)

            unless cart
              # check inside specs for the cartridge object,
              # since d/l carts are not stored in the application yet
              cart = specs.map {|s| s.cartridge if s.cartridge.name == component.cartridge_name }.compact.first
            end

            # checking web_framework/service categories is done to ensure that the cart does not have plugin as well as service categories
            # checking for is_plugin to ensure that the cart has at least one of these categories
            scalable_carts << cart if cart.has_scalable_categories? or !cart.is_plugin?
          end

          # multiple independently scaling carts are not allowed to co-locate with each other
          # ensure that there is only one scaling (non-sparse; non-plugin) cartridge in a group
          if self.scalable and scalable_carts.size > 1
            raise OpenShift::UserException.new("Cartridges #{scalable_carts.map {|c| c.name}} cannot be grouped together as they scale individually")
          end
        end
      end
    end

    # Only one web_framework is allowed
    if (cartridges + component_instances).inject(0){ |c, cart| cart.is_web_framework? ? c + 1 : c } > 1
      raise OpenShift::UserException.new("You can only have one web cartridge in your application '#{name}'.", 109, 'cartridge')
    end

    # Only one web proxy is allowed
    if (cartridges + component_instances).inject(0){ |c, cart| cart.is_web_proxy? ? c + 1 : c } > 1
      raise OpenShift::UserException.new("You can only have one proxy cartridge in your application '#{name}'.", 109, 'cartridge')
    end

    Lock.run_in_app_lock(self) do
      op_group = AddFeaturesOpGroup.new(
        features: cartridges.map(&:name), # For old data support
        cartridges: cartridges.map(&:specification_hash), # Replaces features
        group_overrides: group_overrides, init_git_url: init_git_url,
        user_env_vars: user_env_vars, user_agent: self.user_agent,
        region_id: region_id
      )
      self.pending_op_groups << op_group

      # if the app is not persisted, it means its an app creation request
      # in this case, calculate the pending_ops and execute the pre-save ones
      # this ensures that the app document is not saved without basic embedded documents in place
      # Note: when the scheduler is implemented, these steps (except the call to run_jobs)
      # will be moved out of the lock
      begin
        op_group.elaborate(self)
        op_group.pre_execute(io)
        save!
      rescue
        op_group.unreserve_gears(op_group.num_gears_added, self)
        raise
      end unless self.persisted?

      self.run_jobs(io)
    end

    # adding this feature may have caused pending_ops to be created on the domain
    # for adding env vars and ssh keys
    # execute run_jobs on the domain to take care of those
    domain.reload
    domain.run_jobs
    io
  end

  ##
  # Removes cartridges from the application
  # @param cartridges [Array<Cartridge>] List of cartridges to remove from the application. Each feature will be resolved to the cartridge which provides it
  # @param group_overrides [Array] List of group overrides
  # @param force [Boolean] Set to true when deleting an application. It allows removal of web_proxy and ignores missing cartridges
  # @param remove_all_cartridges [Boolean] Set to true when deleting an application.
  #        It allows recomputing the list of cartridges within the application after acquiring the lock.
  #        If set to true, this ignores the cartridges argument
  # @return [ResultIO] Output from cartridges
  # @raise [OpenShift::UserException] Exception raised if there is any reason the cartridge cannot be removed from the Application
  def remove_cartridges(cartridges=nil, io=ResultIO.new)
    remove_all_cartridges = cartridges.nil?

    cartridges =
      if remove_all_cartridges
        component_ids = component_instances.map(&:_id).map(&:to_s)
        self.cartridges
      else
        component_ids = []
        explicit = cartridges.map do |cart_provided|
          cart = cart_provided.is_a?(String) ? CartridgeCache.find_cartridge(cart_provided, self) : cart_provided
          raise OpenShift::UserException.new("The cartridge '#{cart_provided}' can not be found.", 109) if cart.nil?

          instances = self.component_instances.where(cartridge_name: cart.name)
          raise OpenShift::UserException.new("'#{cart.name}' cannot be removed", 137) if (cart.is_web_proxy? and self.scalable) or cart.is_web_framework?
          raise OpenShift::UserException.new("'#{cart.name}' is not a cartridge of '#{self.name}'", 135) if instances.blank?
          component_ids += instances.map(&:_id).map(&:to_s)
          cart
        end

        original = self.cartridges.to_a
        removed = original - self.class.only_satisfied_dependencies(original - explicit)
        if (removed - explicit).present?
          Rails.logger.debug("Removing dependencies #{(removed - explicit).map(&:name).to_sentence} along with #{explicit.map(&:name).to_sentence}")
        end
        removed
      end

    cartridges.each{ |cart| remove_dependent_cartridges(cart, io) }

    valid_domain_jobs = ((self.domain.system_ssh_keys.any?{ |k| component_ids.include? k.component_id.to_s }) || (self.domain.env_vars.any?{ |e| component_ids.include? e['component_id'].to_s })) rescue true

    Lock.run_in_app_lock(self) do
      op_group = RemoveFeaturesOpGroup.new(features: cartridges.map(&:name), remove_all_features: remove_all_cartridges, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      self.run_jobs(io)
    end

    return io if !valid_domain_jobs

    # removing this cartridge may have caused pending_ops to be created on the domain
    # for removing env vars and ssh keys
    # execute run_jobs on the domain to take care of those
    domain.reload
    domain.run_jobs
    io
  end

  ##
  # Removes cartridges on other applications in this domain that may depend on this cartridge's functionality.
  #
  # Deserves a serious refactoring - instead of relying on individual cartridge categories to determine if any
  # dependent cartridges need to be removed in other applications, we should rely on linkages created between
  # cartridges and applications.
  #
  def remove_dependent_cartridges(cart, io=ResultIO.new)
    if cart.is_ci_server?
      self.domain.applications.each do |app|
        next if self == app
        app.cartridges(true) do |ucart|
          if ucart.is_ci_builder?
            Lock.run_in_app_lock(app) do
              op_group = RemoveFeaturesOpGroup.new(features: [ucart.name], user_agent: app.user_agent)
              app.pending_op_groups << op_group
              app.run_jobs(cart_io = ResultIO.new)
              if cart_io.exitcode == 0
                cart_io.resultIO.string = "Removed #{ucart.name} from #{app.name}\n"
              end
              io.append(cart_io)
            end
          end
        end
      end
    end
    io
  end

  ##
  # Destroys all gears on the application.
  # @return [ResultIO] Output from cartridges
  def destroy_app(io=ResultIO.new)
    remove_dependent_applications(io)
    remove_cartridges(nil, io)
    notify_observers(:after_destroy)
    io
  end

  ##
  # Destroys all applications that depend on this application
  #
  def remove_dependent_applications(io=ResultIO.new)
    Application.where(domain_id: domain_id, builder_id: _id).each{ |app| app.destroy_app(io) }
    io
  end

  ##
  # Update the application's group overrides such that a scalable application becomes HA
  # This broadly means setting the 'min' of web_proxy sparse cart to 2
  def make_ha
    raise OpenShift::UserException.new("This feature ('High Availability') is currently disabled. Enable it in OpenShift's config options.") if not Rails.configuration.openshift[:allow_ha_applications]
    raise OpenShift::UserException.new("'High Availability' is not an allowed feature for the account ('#{self.domain.owner.login}')") if not self.domain.owner.ha
    raise OpenShift::UserException.new("Only scalable applications can be made 'HA'") if not self.scalable
    raise OpenShift::UserException.new("Application is already HA") if self.ha

    component_instance = self.component_instances.detect{ |i| i.cartridge.is_web_proxy? } or
      raise OpenShift::UserException.new("Cannot make the application HA because there is no web cartridge.")
    raise OpenShift::UserException.new("Cannot make the application HA because the web cartridge's max gear limit is '1'") if component_instance.group_instance.group_override.max_gears==1

    Lock.run_in_app_lock(self) do
      pending_op_groups << MakeAppHaOpGroup.new(user_agent: self.user_agent)
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # Update the application's group overrides such that a scalable application ceases to be HA
  # This broadly means setting the 'min' of web_proxy sparse cart to 1
  def disable_ha
    raise OpenShift::UserException.new("HA is not active for this application.") if !self.ha
    raise OpenShift::UserException.new("HA operations are allowed only on scalable applications") if not self.scalable

    component_instance = self.component_instances.detect{ |i| i.cartridge.is_web_proxy? } or
      raise OpenShift::UserException.new("Cannot disable HA because there is no web cartridge.")

    Lock.run_in_app_lock(self) do
      pending_op_groups << DisableAppHaOpGroup.new(user_agent: self.user_agent)
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # Create and add group overrides to update scaling and filesystem limits for a the {GroupInstance} hosting a {ComponentInstance}
  # @param component_instance [ComponentInstance] The component instance to use when creating the override definition
  # @param scale_from [Integer] Minimum scale for the component
  # @param scale_to [Integer] Maximum scale for the component
  # @param additional_filesystem_gb [Integer] Gb of disk storage required beyond is default in the gear size
  # @return [ResultIO] Output from cartridges
  # @raise [OpenShift::UserException] Exception raised if request cannot be completed
  def update_component_limits(component_instance, scale_from, scale_to, additional_filesystem_gb, multiplier=nil)
    if additional_filesystem_gb && additional_filesystem_gb != 0
      max_storage = self.domain.owner.max_storage
      raise OpenShift::UserException.new("This application is not allowed to have additional gear storage", 164) if max_storage == 0
      raise OpenShift::UserException.new("You have requested more additional gear storage than you are allowed (max: #{max_storage} GB)", 166) if additional_filesystem_gb > max_storage
    end
    raise OpenShift::UserException.new("Cannot set the max gear limit to '1' if the application is HA (highly available)") if self.ha and scale_to==1

    if (scale_from or scale_to) and !(component_instance.has_scalable_categories? or component_instance.is_sparse?)
      raise OpenShift::UserException.new("You can not set scaling policies for #{component_instance.cartridge_name}. Generally, you can set it only for web_framework or service cartridges.")
    end

    if component_instance.is_external?
      raise OpenShift::UserException.new("You can not set the multiplier for an external cartridge.") if multiplier
      raise OpenShift::UserException.new("You can not add storage for an external cartridge.") if additional_filesystem_gb and additional_filesystem_gb != 0
    end

    Lock.run_in_app_lock(self) do
      op_group = UpdateCompLimitsOpGroup.new(comp_spec: component_instance.to_component_spec, min: scale_from, max: scale_to, multiplier: multiplier, additional_filesystem_gb: additional_filesystem_gb, user_agent: self.user_agent)
      pending_op_groups << op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # Run a job to recompute usage tracking when the max additional untracked storage for this application changes
  # @param old_untracked [Integer] previous maximum additional untracked storage amount
  # @param new_untracked [Integer] new maximum additional untracked storage amount
  def change_max_untracked_storage(old_untracked, new_untracked)
    Lock.run_in_app_lock(self) do
      if group_instances_with_overrides.find {|group| group.additional_filesystem_gb > 0 }
        pending_op_groups << ChangeMaxUntrackedStorageOpGroup.new(user_agent: self.user_agent, old_untracked: old_untracked, new_untracked: new_untracked)
        result_io = ResultIO.new
        self.run_jobs(result_io)
        result_io
      end
    end
  end

  ##
  # Return an array of operations to run as a result of changing the maximum additional untracked storage amount for this application
  def calculate_change_max_untracked_storage_ops(old_untracked, new_untracked)
    ops = []
    owner = self.domain.owner
    group_instances_with_overrides.each do |override|
      if (fs = override.additional_filesystem_gb) > 0
        override.instance.gears.each do |gear|
          ops << TrackUsageOp.new(
            user_id:                          owner._id,
            parent_user_id:                   owner.parent_user_id,
            app_name:                         self.name,
            gear_id:                          gear._id.to_s,
            event:                            UsageRecord::EVENTS[:end],
            usage_type:                       UsageRecord::USAGE_TYPES[:addtl_fs_gb],
            additional_filesystem_gb:         fs,
            max_untracked_additional_storage: old_untracked,
            skip_user_lock:                   true,
            prereq:                           ops.last ? [ops.last._id.to_s] : [])

          ops << TrackUsageOp.new(
            user_id:                          owner._id,
            parent_user_id:                   owner.parent_user_id,
            app_name:                         self.name,
            gear_id:                          gear._id.to_s,
            event:                            UsageRecord::EVENTS[:begin],
            usage_type:                       UsageRecord::USAGE_TYPES[:addtl_fs_gb],
            additional_filesystem_gb:         fs,
            max_untracked_additional_storage: new_untracked,
            skip_user_lock:                   true,
            prereq:                           ops.last ? [ops.last._id.to_s] : [])
        end
      end
    end
    ops
  end

  ##
  # Trigger a scale up or scale down of a {GroupInstance}
  # @param group_instance_id [String] ID of the {GroupInstance}
  # @param scale_by [Integer] Number of gears to scale add/remove from the {GroupInstance}.
  #   A positive value will trigger a scale up and a negative value a scale down
  # @return [ResultIO] Output from cartridges
  # @raise [OpenShift::UserException] Exception raised if request cannot be completed
  def scale_by(group_instance_id, scale_by)
    raise OpenShift::UserException.new("Application #{self.name} is not scalable") if !self.scalable

    override = group_instances_with_overrides.detect{ |i| i.instance._id === group_instance_id}
    current = override.instance.gears.length
    raise OpenShift::UserException.new("Cannot scale down below gear limit of #{override.min_gears}.", 168) if (current+scale_by) < override.min_gears
    raise OpenShift::UserException.new("Cannot scale up above maximum gear limit of #{override.max_gears}.", 168) if (scale_by > 0) && (current+scale_by) > override.max_gears && override.max_gears != -1

    Lock.run_in_app_lock(self) do
      op_group = ScaleOpGroup.new(group_instance_id: group_instance_id, scale_by: scale_by, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  ##
  # Returns the fully qualified DNS name for an application gear (unless specified, the primary)
  # @return [String]
  def fqdn(gear_name = nil)
    "#{gear_name || canonical_name}-#{domain_namespace}.#{Rails.configuration.openshift[:domain_suffix]}"
  end

  ##
  # Returns the application URL with the proper protocol (http vs https) based on configuration
  # @return [String]
  def app_url
    proto = Rails.application.config.openshift[:app_advertise_https] ? "https" : "http"
    "#{proto}://#{fqdn()}/"
  end

  ##
  # Returns the SSH URI for an application gear (unless specified, the primary)
  # @return [String]
  def ssh_uri(gear_uuid=nil)
    if gear_uuid # specific gear_uuid requested
      if gears.where(uuid: gear_uuid).count > 0
        gear = gears.find_by(uuid: gear_uuid)
        return "#{gear_uuid}@#{fqdn(gear.name)}"
      end
    elsif gears.where(app_dns: true).count > 0
      # get the gear_uuid of head gear
      gear = gears.find_by(app_dns: true)
      return "#{gear.uuid}@#{fqdn}"
    end
    ""
  end

  ##
  # Retrieves the gear state for all gears within the application.
  # @return [Hash<String, String>] Map of {Gear} ID to state
  def get_gear_states(timeout=nil)
    gear_states, result_io = Gear.get_gear_states(self.gears, timeout)
    [gear_states, result_io]
  end

  ##
  # Returns the application descriptor as a Hash. The descriptor contains all the metadata
  # necessary to describe the application.
  # @requires [Hash]
  def to_descriptor
    h = {
      "Name" => self.name,
      "Requires" => self.cartridges(true).map(&:name)
    }

    h["Group-Overrides"] = self.group_overrides unless self.group_overrides.empty?

    h
  end

  ##
  # Start an application of feature
  # @param feature [String, #optional] Optional feature name to start. If nil, it will trigger start on all features in the application
  # @return [ResultIO] Output from cartridges
  def start(feature=nil)
    result_io = ResultIO.new
    op_group = nil
    if feature.nil?
      op_group = StartAppOpGroup.new(user_agent: self.user_agent)
    else
      op_group = StartFeatureOpGroup.new(feature: feature, user_agent: self.user_agent)
    end
    Lock.run_in_app_lock(self) do
      self.pending_op_groups << op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def start_component(component_name, cartridge_name)
    Lock.run_in_app_lock(self) do
      result_io = ResultIO.new
      op_group = StartCompOpGroup.new(comp_spec: ComponentSpec.new(component_name, cartridge_name).to_component_spec, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def stop(feature=nil, force=false)
    Lock.run_in_app_lock(self) do
      result_io = ResultIO.new
      op_group = nil
      if feature.nil?
        op_group = StopAppOpGroup.new(force: force, user_agent: self.user_agent)
      else
        op_group = StopFeatureOpGroup.new(feature: feature, force: force, user_agent: self.user_agent)
      end
      self.pending_op_groups << op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def stop_component(component_name, cartridge_name, force=false)
    Lock.run_in_app_lock(self) do
      result_io = ResultIO.new
      op_group = StopCompOpGroup.new(comp_spec: ComponentSpec.new(component_name, cartridge_name).to_component_spec, force: force, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def restart(feature=nil)
    Lock.run_in_app_lock(self) do
      result_io = ResultIO.new
      op_group = nil
      if feature.nil?
        op_group = RestartAppOpGroup.new(user_agent: self.user_agent)
      else
        op_group = RestartFeatureOpGroup.new(feature: feature, user_agent: self.user_agent)
      end
      self.pending_op_groups << op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def restart_component(component_name, cartridge_name)
    Lock.run_in_app_lock(self) do
      result_io = ResultIO.new
      op_group = RestartCompOpGroup.new(comp_spec: ComponentSpec.new(component_name, cartridge_name).to_component_spec, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def reload_config(feature=nil)
    Lock.run_in_app_lock(self) do
      result_io = ResultIO.new
      op_group = nil
      if feature.nil?
        op_group = ReloadAppConfigOpGroup.new(user_agent: self.user_agent)
      else
        op_group = ReloadFeatureConfigOpGroup.new(feature: feature, user_agent: self.user_agent)
      end
      self.pending_op_groups << op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def threaddump
    threaddump_available = false
    result_io = ResultIO.new
    component_instances.each do |component_instance|
      if component_instance.supports_action?("threaddump")
        threaddump_available = true
        GroupInstance.run_on_gears(component_instance.gears, result_io, false) do |gear, r|
          r.append gear.threaddump(component_instance)
        end
      end
    end
    raise OpenShift::UserException.new("The threaddump command is not available for this application", 180) if !threaddump_available
    result_io
  end

  def reload_component_config(component_name, cartridge_name)
    Lock.run_in_app_lock(self) do
      op_group = ReloadCompConfigOpGroup.new(comp_spec: ComponentSpec.new(component_name, cartridge_name).to_component_spec, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  def tidy
    Lock.run_in_app_lock(self) do
      result_io = ResultIO.new
      op_group = TidyAppOpGroup.new(user_agent: self.user_agent)
      self.pending_op_groups << op_group
      self.run_jobs(result_io)
      result_io
    end
  end

  def show_port
    #TODO
    raise "noimpl"
  end

  def remove_gear(gear_id)
    raise OpenShift::UserException.new("Application #{self.name} is not scalable") if !self.scalable
    raise OpenShift::UserException.new("Gear for removal not specified") if gear_id.nil?
    Lock.run_in_app_lock(self) do
      op_group = RemoveGearOpGroup.new(gear_id: gear_id, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  # NO LONGER USED: Remove
  def status(feature=nil)
    result_io = ResultIO.new
    self.component_instances.each do |instance|
      next if feature && instance.cartridge_name != feature
      GroupInstance.run_on_gears(instance.gears, result_io, false) do |gear, r|
        next if not gear.has_component?(instance)
        r.append gear.status(instance)
      end
    end
    result_io
  end

  def component_status(component_instance)
    result_io = ResultIO.new
    status_messages = []
    GroupInstance.run_on_gears(component_instance.gears, result_io, false) do |gear, r|
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
  # ssl_certificate:: SSL certificate to add
  # private_key::Private key for the SSL certificate
  # pass_phrase::Optional passphrase for the private key
  #
  # == Returns:
  # {PendingAppOps} object which tracks the progress of the operation.
  #
  # == Raises:
  # OpenShift::UserException if the alias is already been associated with an application.
  def add_alias(fqdn, ssl_certificate=nil, private_key=nil, pass_phrase="")
    # Server aliases validate as DNS host names in accordance with RFC
    # 1123 and RFC 952.  Additionally, OpenShift does not allow an
    # Alias to be an IP address or a host in the service domain.
    # Since DNS is case insensitive, all names are downcased for
    # indexing/compares.
    server_alias = validate_alias(fqdn) or
      raise OpenShift::UserException.new("The specified alias is not allowed: '#{fqdn}'", 105, "id")
    validate_certificate(ssl_certificate, private_key, pass_phrase)

    Lock.run_in_app_lock(self) do
      # Normally, do not allow two apps to register the same alias. Unless configured.
      raise OpenShift::UserException.new("Alias #{server_alias} is already registered", 140, "id") if
        Rails.configuration.openshift[:prevent_alias_collision] and Application.where("aliases.fqdn" => server_alias).count > 0

      op_group = AddAliasOpGroup.new(fqdn: server_alias, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      if ssl_certificate.present?
        op_group = AddSslCertOpGroup.new(fqdn: server_alias, ssl_certificate: ssl_certificate, private_key: private_key, pass_phrase: pass_phrase, user_agent: self.user_agent)
        self.pending_op_groups << op_group
      end
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  def validate_alias(fqdn)
    return false if fqdn.nil? || fqdn.length > 255 || fqdn.length == 0
    fqdn.downcase!
    return false if fqdn =~ /^\d+\.\d+\.\d+\.\d+$/
    return false if fqdn =~ /\A[\S]+(\.(json|xml|yml|yaml|html|xhtml))\z/
    return false if not fqdn =~ /\A[a-z0-9]+([\.]?[\-a-z0-9]+)+\z/
    conf = Rails.configuration.openshift
    if fqdn.end_with?(cloud_domain = conf[:domain_suffix])
      # Normally, do not allow creating an alias in the cloud domain. Unless configured.
      return false unless conf[:allow_alias_in_domain]
      # Even then, still exclude those that could conflict with app names. Unless configured.
      return false if fqdn.chomp(cloud_domain) =~ /\A\w+-\w+\.\z/ and conf[:prevent_alias_collision]
    end
    return fqdn
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
    fqdn = fqdn.downcase if fqdn
    al1as = aliases.find_by(fqdn: fqdn)
    Lock.run_in_app_lock(self) do
      if al1as.has_private_ssl_certificate
         op_group = RemoveSslCertOpGroup.new(fqdn: al1as.fqdn, user_agent: self.user_agent)
         self.pending_op_groups << op_group
      end
      op_group = RemoveAliasOpGroup.new(fqdn: al1as.fqdn, user_agent: self.user_agent)
      self.pending_op_groups << op_group
      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  def update_alias(fqdn, ssl_certificate=nil, private_key=nil, pass_phrase="")

    validate_certificate(ssl_certificate, private_key, pass_phrase)

    fqdn = fqdn.downcase if fqdn
    old_alias = aliases.find_by(fqdn: fqdn)
    Lock.run_in_app_lock(self) do
      #remove old certificate
      if old_alias.has_private_ssl_certificate
         op_group = RemoveSslCertOpGroup.new(fqdn: fqdn, user_agent: self.user_agent)
         self.pending_op_groups << op_group
      end
      #add new certificate
      if ssl_certificate.present?
        op_group = AddSslCertOpGroup.new(fqdn: fqdn, ssl_certificate: ssl_certificate, private_key: private_key, pass_phrase: pass_phrase, user_agent: self.user_agent)
        self.pending_op_groups << op_group
      end

      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  def get_web_framework_gears
    [].tap do |gears|
      component_instances.each do |ci|
        ci.gears.each do |gear|
          unless gear.removed
            gears << gear if ci.is_web_framework?
          end
        end
      end
    end.flatten.uniq
  end

  def get_web_proxy_gears
    [].tap do |gears|
      component_instances.each do |ci|
        ci.gears.each do |gear|
          unless gear.removed
            gears << gear if ci.is_web_proxy?
          end
        end
      end
    end.flatten.uniq
  end

  # Updates the gear registry on all proxy gears and invokes each proxy cartridge's
  # update-cluster control method so it can update its configuration as well.
  #
  # options may contain rollback:true to indicate this is a rollback
  def update_cluster(options={})
    web_proxy_gears = get_web_proxy_gears
    return if web_proxy_gears.empty?

    web_framework_gears = get_web_framework_gears

    # we don't want to have all the proxies down at the same time, so do the
    # first one by itself, wait for it to finish, and then do the rest in
    # parallel
    first_proxy = web_proxy_gears.first

    options[:proxy_gears] = web_proxy_gears
    options[:web_gears] = web_framework_gears

    first_proxy.update_cluster(options.merge(sync_new_gears:true))

    if web_proxy_gears.size > 1
      # do the rest
      handle = RemoteJob.create_parallel_job

      web_proxy_gears[1..-1].each do |gear|
        job = gear.get_update_cluster_job(options)
        RemoteJob.add_parallel_job(handle, "", gear, job)
      end

      # TODO consider doing multiple batches of jobs in parallel, instead of 1 big
      # parallel job
      RemoteJob.execute_parallel_jobs(handle)

      RemoteJob.get_parallel_run_results(handle) do |tag, gear_id, output, status|
        if status != 0
          Rails.logger.error "Update cluster failed:: tag: #{tag}, gear_id: #{gear_id},"\
                             "output: #{output}, status: #{status}"
        end
      end
    end
  end

  # Enables or disables a target gear in all proxies
  #
  # options:
  #  :action - :enable or :disable
  #  :gear_uuid - target gear uuid to enable/disable
  #  :persist - if true, update the proxy configuration on disk
  def update_proxy_status(options)
    web_proxy_gears = get_web_proxy_gears
    return if web_proxy_gears.empty?

    handle = RemoteJob.create_parallel_job
    web_proxy_gears.each do |gear|
      RemoteJob.add_parallel_job(handle, "", gear, gear.get_update_proxy_status_job(options))
    end

    RemoteJob.execute_parallel_jobs(handle)

    RemoteJob.get_parallel_run_results(handle) do |tag, gear_id, output, status|
      if status != 0
        Rails.logger.error "Update proxy status failed:: tag: #{tag}, gear_id: #{gear_id},"\
                           "output: #{output}, status: #{status}"
      end
    end
  end

  def run_connection_hooks
    Lock.run_in_app_lock(self) do
      op_group = ExecuteConnectionsOpGroup.new()
      self.pending_op_groups << op_group

      result_io = ResultIO.new
      self.run_jobs(result_io)
      result_io
    end
  end

  def set_connections(connections)
    conns = []
    self.connections = [] unless connections.present?
    connections.each do |conn_info|
      from = self.find_component_instance_for(conn_info["from_comp_inst"])
      to = self.find_component_instance_for(conn_info["to_comp_inst"])
      conns.push(ConnectionInstance.new(from._id, to._id,
            conn_info["from_connector_name"], conn_info["to_connector_name"], conn_info["connection_type"]))
    end
    self.connections = conns
  end

  ##
  # Generate a Hash of unsubscribe information (must be serializable to mongo directly)
  #
  def get_unsubscribe_info(comp_inst)
    old_connections, _, _ = elaborate(self.cartridges << comp_inst.cartridge)
    sub_pub_hash = {}
    if self.scalable and old_connections
      old_connections.each do |conn|
        if comp_inst.matches_spec?(conn["from_comp_inst"])
          sub_pub_hash[conn["to_comp_inst"].path] = [conn["to_comp_inst"].mongoize, conn["from_comp_inst"].mongoize]
        end
      end
    end
    sub_pub_hash
  end

  def execute_connections
    return if not self.scalable

    # Initialize self.connections.
    connections, _, _ = elaborate(self.cartridges, self.group_overrides)
    set_connections(connections)

    # Run the publish hooks on each gear and get their output.
    Rails.logger.debug "Running publishers"
    handle = RemoteJob.create_parallel_job
    self.connections.each do |conn|
      pub_inst = self.component_instances.find(conn.from_comp_inst_id)
      tag = conn._id.to_s

      pub_inst.gears.each do |gear|
        input_args = [gear.name, self.domain_namespace, gear.uuid]
        unless gear.removed
          job = gear.get_execute_connector_job(pub_inst, conn.from_connector_name, conn.connection_type, input_args)
          RemoteJob.add_parallel_job(handle, tag, gear, job)
        end
      end
    end

    pub_out = {}
    RemoteJob.execute_parallel_jobs(handle)
    RemoteJob.get_parallel_run_results(handle) do |tag, gear_id, output, status|
      # Ignore the hook's output if it did not complete successfully.
      next if status != 0

      # Filter out CLIENT_* lines that the runtime may have added.
      # For example, execute_parallel_action calls report_quota,
      # which may add "CLIENT_MESSAGE Warning:" lines about quota
      # exhaustion to the output.
      re = /^CLIENT_(MESSAGE|RESULT|DEBUG|ERROR|INTERNAL_ERROR)/
      output = output.lines.reject {|line| line =~ re}.join

      conn_type = self.connections.find { |c| c._id.to_s == tag}.connection_type
      if conn_type.start_with?("ENV:")
        pub_out[tag] = {} if pub_out[tag].nil?

        # Output from an ENV: publish hook includes one or more
        # environment variable assignments of the form "var=value\n".
        # Copy them verbatim for subscribe hooks.
        pub_out[tag][gear_id] = output
      else
        pub_out[tag] = [] if pub_out[tag].nil?

        # Output from a non-ENV: publish hook may be terminated by
        # "\n", but we do not want to include the "\n" in the input to
        # the subscribe hook.
        output.rstrip!

        # Output from a non-ENV: publish hook generally includes some
        # gear-specific parameter.  Subscribe hooks should expect to
        # receive a list of these parameters formatted as
        # "'gearuuid'='parameter'" (with the single-quotes but without
        # the double-quotes) joined by spaces.
        pub_out[tag].push("'#{gear_id}'='#{output}'")
      end
    end

    # Run the subscribe hooks, providing them the output of the publish
    # hooks as their input.
    Rails.logger.debug "Running subscribers"
    handle = RemoteJob.create_parallel_job
    self.connections.each do |conn|
      pub_inst = self.component_instances.find(conn.from_comp_inst_id)
      sub_inst = self.component_instances.find(conn.to_comp_inst_id)
      tag = ""

      unless pub_out[conn._id.to_s].nil?
        if conn.connection_type.start_with?("ENV:")
          input_to_subscriber = pub_out[conn._id.to_s]
        else
          input_to_subscriber = Shellwords::shellescape(pub_out[conn._id.to_s].join(' '))
        end

        Rails.logger.debug "Output of publisher - '#{pub_out}'"
        sub_inst.gears.each do |gear|
          input_args = [gear.name, self.domain_namespace, gear.uuid, input_to_subscriber]
          unless gear.removed
            job = gear.get_execute_connector_job(sub_inst, conn.to_connector_name, conn.connection_type, input_args, pub_inst.cartridge_name)
            RemoteJob.add_parallel_job(handle, tag, gear, job)
          end
        end
      end
    end
    RemoteJob.execute_parallel_jobs(handle)
    Rails.logger.debug "Connections done"
  end

  #private

  ##
  # Retrieve the gear with application dns.
  # @return [Gear] gear object
  def get_app_dns_gear
    if gears.where(app_dns: true).count > 0
      return gears.find_by(app_dns: true)
    end
    raise OpenShift::UserException.new("Gear containing application dns not found")
  end

  def deregister_routing_dns
    ha_dns_prefix = Rails.configuration.openshift[:ha_dns_prefix]
    ha_dns_suffix = Rails.configuration.openshift[:ha_dns_suffix]
    dns = OpenShift::DnsService.instance
    begin
      dns.deregister_application("#{ha_dns_prefix}#{self.name}", "#{self.domain.namespace}#{ha_dns_suffix}")
      dns.publish
    ensure
      dns.close
    end
  end

  def register_routing_dns
    ha_dns_prefix = Rails.configuration.openshift[:ha_dns_prefix]
    ha_dns_suffix = Rails.configuration.openshift[:ha_dns_suffix]
    target_hostname = Rails.configuration.openshift[:router_hostname]
    dns = OpenShift::DnsService.instance
    begin
      dns.register_application("#{ha_dns_prefix}#{self.name}", "#{self.domain.namespace}#{ha_dns_suffix}", target_hostname)
      dns.publish
    ensure
      dns.close
    end
  end

  def members_changed(added, removed, changed_roles, parent_op)
    op_group = ChangeMembersOpGroup.new(members_added: added.presence, members_removed: removed.presence, roles_changed: changed_roles.presence, user_agent: self.user_agent, parent_op: parent_op)
    self.pending_op_groups << op_group
  end

  # Processes directives returned by component hooks to add/remove domain ssh keys, app ssh keys, env variables, broker keys etc
  # @note {#run_jobs} must be called in order to perform the updates
  #
  # == Parameters:
  # result_io::
  #   {ResultIO} object with directives from cartridge hooks
  def process_commands(result_io, component_id=nil, gear=nil)
    commands = result_io.cart_commands
    add_ssh_keys = []

    remove_env_vars = []

    domain_keys_to_add = []

    domain_env_vars_to_add = []

    commands.each do |command_item|
      case command_item[:command]
      when "SYSTEM_SSH_KEY_ADD"
        domain_keys_to_add.push(SystemSshKey.new(name: self.name, type: "ssh-rsa", content: command_item[:args][0], component_id: component_id))
      when "APP_SSH_KEY_ADD"
        id = (gear.nil?) ? component_id : gear._id
        add_ssh_keys << ApplicationSshKey.new(name: command_item[:args][0], type: "ssh-rsa", content: command_item[:args][1], created_at: Time.now, component_id: id)
      when "APP_ENV_VAR_REMOVE"
        remove_env_vars.push({"key" => command_item[:args][0]})
      when "ENV_VAR_ADD"
        domain_env_vars_to_add.push({"key" => command_item[:args][0], "value" => command_item[:args][1], "component_id" => component_id, "unique" => false})
      when "ENV_VAR_ADD_UNIQUE"
        domain_env_vars_to_add.push({"key" => command_item[:args][0], "value" => command_item[:args][1], "component_id" => component_id, "unique" => true})
      when "BROKER_KEY_ADD"
        op_group = AddBrokerAuthKeyOpGroup.new(user_agent: self.user_agent)
        op_group.set_created_at
        Application.where(_id: self._id).update_all({ "$push" => { pending_op_groups: op_group.as_document } })
      when "NOTIFY_ENDPOINT_CREATE"
        if gear
          pi = PortInterface.create_port_interface(gear, component_id, *command_item[:args])
          gear.port_interfaces.push(pi)
          pi.publish_endpoint(self)
        end
      when "NOTIFY_ENDPOINT_DELETE"
        if gear
          public_ip, public_port = command_item[:args]
          if pi = PortInterface.find_port_interface(gear, public_ip, public_port)
            pi.unpublish_endpoint(self, public_ip)
            gear.port_interfaces.delete(pi)
          end
        end
      end
    end

    if add_ssh_keys.length > 0
      keys_attrs = get_updated_ssh_keys(add_ssh_keys)
      op_group = UpdateAppConfigOpGroup.new(add_keys_attrs: keys_attrs, user_agent: self.user_agent)
      op_group.set_created_at
      Application.where(_id: self._id).update_all({ "$push" => { pending_op_groups: op_group.as_document }, "$pushAll" => { app_ssh_keys: keys_attrs }})
    end
    if remove_env_vars.length > 0
      op_group = UpdateAppConfigOpGroup.new(remove_env_vars: remove_env_vars)
      op_group.set_created_at
      Application.where(_id: self._id).update_all({ "$push" => { pending_op_groups: op_group.as_document }})
    end

    # Have to remember to run_jobs for the other apps involved at some point
    # run_jobs is called on the domain after all processing is done from add_cartridges and remove_cartridges
    domain.add_system_ssh_keys(domain_keys_to_add) if !domain_keys_to_add.empty?
    domain.add_env_variables(domain_env_vars_to_add) if !domain_env_vars_to_add.empty?
    nil
  end

  # Runs all pending jobs and stops at the first failure.
  #
  # IMPORTANT: Callers should take the application lock prior to calling run_jobs
  #
  # IMPORTANT: When changing jobs, be sure to leave old jobs runnable so that pending_ops
  #   that are inserted during a running upgrade can continue to complete.
  #
  # == Returns:
  # True on success or False if no pending jobs.
  def run_jobs(result_io=nil, continue_on_successful_rollback=false)
    result_io = ResultIO.new if result_io.nil?
    op_group = nil
    while self.pending_op_groups.count > 0
      rollback_pending = false
      op_group = self.pending_op_groups.first
      self.user_agent = op_group.user_agent

      begin
        op_group.elaborate(self) if op_group.pending_ops.count == 0

        if op_group.pending_ops.where(:state => :rolledback).count > 0
          rollback_pending = true
          # making sure that the rollback_blocked flag is not accidentally set to true
          # triggering a rollback while blocking the rollback at the same time could result in an infinite loop
          op_group.set :rollback_blocked, false if op_group.rollback_blocked
          raise Exception.new("Op group is already being rolled back.")
        end

        op_group.execute(result_io)
        op_group.unreserve_gears(op_group.num_gears_removed, self)
        op_group.delete
      rescue Exception => e_orig
        Rails.logger.error "Encountered error during execute '#{e_orig.message}'"
        # don't log the error stacktrace if this exception was raised just to trigger a rollback
        Rails.logger.debug e_orig.backtrace.inspect unless rollback_pending

        #rollback
        rollback_successful = false
        begin
          # reload the application before a rollback
          self.reload
          op_group.execute_rollback(result_io)
          op_group.delete
          num_gears_recovered = op_group.num_gears_added - op_group.num_gears_created + op_group.num_gears_rolled_back + op_group.num_gears_destroyed
          op_group.unreserve_gears(num_gears_recovered, self)

          rollback_successful = true
        rescue Mongoid::Errors::DocumentNotFound
          # ignore if the application is already deleted
        rescue Exception => e_rollback
          Rails.logger.error "Error during rollback"
          Rails.logger.error e_rollback.message
          Rails.logger.error e_rollback.backtrace.join("\n")

          # if the original exception was raised just to trigger a rollback
          # then the rollback exception is the only thing of value and hence return/raise it
          raise e_rollback if rollback_pending
        end unless op_group.rollback_blocked

        # raise the original exception if it was the actual exception that led to the rollback
        # if not, then we should just continue execution of any remaining op_groups.
        # The continue_on_successful_rollback flag is used by the oo-admin-clear-pending-ops script
        # Note: If the rollback was blocked, do not continue as this can lead to an infinite loop
        unless ( rollback_successful and (continue_on_successful_rollback or rollback_pending) )
          if e_orig.respond_to? 'resultIO' and e_orig.resultIO
            e_orig.resultIO.append result_io unless e_orig.resultIO == result_io
          end
          raise e_orig
        end
      end

      begin
        self.reload
      rescue Mongoid::Errors::DocumentNotFound
        # ignore the exception, if the application has been deleted
        # the app could be deleted based on the user's app deletion request
        # or it could be the result of a rollback of an app creation request

        # just break out of the loop
        break
      end
    end

    true
  end

  def with_lock(&block)
    Lock.run_in_app_lock(self, &block)
  end

  # Determines if the application's cartridges are colocatable
  # == Returns:
  # True if the app is hosted on a single platform, false otherwise
  def is_collocatable?()
    self.component_instances.map {|comp| comp.get_cartridge.platform }.uniq.size == 1
  end

  def update_requirements(cartridges, replacements, overrides, init_git_url=nil, user_env_vars=nil, region_id=nil)
    current = group_instances_with_overrides
    connections, updated = elaborate(cartridges, overrides)

    upgrades = compute_upgrades(replacements)
    changes, moves = compute_diffs(current, updated, upgrades)
    # ensure that the cart is assigned to a group that is valid
    changes.each do |change|
      if change.to
        change.to.components.each do |component|
          valid_gear_sizes = Rails.application.config.openshift[:cartridge_gear_sizes][component.cartridge.name]
          if !valid_gear_sizes.empty? && !valid_gear_sizes.include?(change.to.gear_size)
            error_message = "The cartridge, #{component.cartridge.name}, cannot run on a gear with size: #{change.to.gear_size}.  Per configuration, the cartridge can only run on the following gear sizes: #{valid_gear_sizes.join ', '}."
            raise OpenShift::UserException.new(error_message)
          end
        end
      end
    end

    if moves.present?
      raise OpenShift::UserException.new("Moving cartridges from one gear group to another is not supported.")
    end
    calculate_ops(changes, moves, connections, updated, init_git_url, user_env_vars, region_id)
  end

  def calculate_remove_group_instance_ops(comp_specs, group_instance, additional_filesystem_gb)
    pending_ops = []
    gear_destroy_ops = calculate_gear_destroy_ops(group_instance._id.to_s,
                                                  group_instance.gears.map{|g| g._id.to_s},
                                                  additional_filesystem_gb)
    pending_ops.concat(gear_destroy_ops)
    gear_destroy_op_ids = gear_destroy_ops.map{ |op| op._id.to_s }

    comp_specs.each do |comp_spec|
      comp_instance = self.find_component_instance_for(comp_spec)
      pending_ops << UnsubscribeConnectionsOp.new(sub_pub_info: get_unsubscribe_info(comp_instance), prereq: gear_destroy_op_ids)
    end

    pending_ops << DeleteGroupInstanceOp.new(group_instance_id: group_instance._id.to_s, prereq: gear_destroy_op_ids)
  end

  def calculate_gear_create_ops(ginst_id, gear_ids, deploy_gear_id, comp_specs, component_ops, additional_filesystem_gb, gear_size,
                                prereq_op=nil, is_scale_up=false, hosts_app_dns=false, init_git_url=nil, user_env_vars=nil, region_id=nil)
    ops = []
    track_usage_ops = []

    gear_id_prereqs = {}
    maybe_notify_app_create_op = []
    app_dns_gear_id = nil

    comp_spec_gears = {}
    gear_comp_specs = {}
    comp_specs.each do |comp_spec|
      sparse_carts_added_count = 0
      gear_ids.each_with_index do |gear_id, index|
        next if not add_sparse_cart?(index, sparse_carts_added_count, comp_spec, is_scale_up)
        sparse_carts_added_count += 1
        comp_spec_gears[comp_spec] = [] unless comp_spec_gears[comp_spec]
        comp_spec_gears[comp_spec] << gear_id
        gear_comp_specs[gear_id] = [] unless gear_comp_specs[gear_id]
        gear_comp_specs[gear_id] << comp_spec
      end
    end

    gear_ids.each do |gear_id|
      host_singletons = (gear_id == deploy_gear_id)
      app_dns = (host_singletons && hosts_app_dns)

      # FIXME this operation should move to much later in the process (DNS must be registered before publishing this route)
      if app_dns
        notify_app_create_op = NotifyAppCreateOp.new()
        ops << notify_app_create_op
        maybe_notify_app_create_op = [notify_app_create_op._id.to_s]
        app_dns_gear_id = gear_id.to_s
      end

      cartridge = CartridgeCache.find_cartridge(comp_specs.first.cartridge_name, self)
      platform = cartridge ? cartridge.platform : nil

      init_gear_op = InitGearOp.new(group_instance_id: ginst_id, platform: platform, gear_id: gear_id,
                                    gear_size: gear_size, addtl_fs_gb: additional_filesystem_gb,
                                    comp_specs: gear_comp_specs[gear_id], host_singletons: host_singletons,
                                    app_dns: app_dns, pre_save: (not self.persisted?))
      init_gear_op.prereq << prereq_op._id.to_s unless prereq_op.nil?

      reserve_uid_op = ReserveGearUidOp.new(gear_id: gear_id, gear_size: gear_size, region_id: region_id, prereq: maybe_notify_app_create_op + [init_gear_op._id.to_s])

      create_gear_op = CreateGearOp.new(gear_id: gear_id, prereq: [reserve_uid_op._id.to_s], retry_rollback_op: reserve_uid_op._id.to_s, is_group_creation: !is_scale_up)
      # this flag is passed to the node to indicate that an sshkey is required to be generated for this gear
      # currently the sshkey is being generated on the app dns gear if the application is scalable
      # we are assuming that haproxy will also be added to this gear
      create_gear_op.sshkey_required = app_dns && self.scalable

      track_usage_ops << TrackUsageOp.new(user_id: self.domain.owner._id, parent_user_id:
                           self.domain.owner.parent_user_id, app_name: self.name, gear_id: gear_id,
                           event: UsageRecord::EVENTS[:begin], usage_type: UsageRecord::USAGE_TYPES[:gear_usage],
                           gear_size: gear_size, prereq: [create_gear_op._id.to_s])

      register_dns_op = RegisterDnsOp.new(gear_id: gear_id, prereq: [create_gear_op._id.to_s])
      register_sso_op = RegisterSsoOp.new(gear_id: gear_id, prereq: [register_dns_op._id.to_s])
      ops.push(init_gear_op, reserve_uid_op, create_gear_op, register_dns_op, register_sso_op)
      # Only register the routing dns here on application creation:
      if self.component_instances == []
        ops.push(RegisterRoutingDnsOp.new(prereq: [register_sso_op._id.to_s])) if self.ha and Rails.configuration.openshift[:manage_ha_dns]
      end

      if additional_filesystem_gb != 0
        # FIXME move into CreateGearOp
        ops << SetAddtlFsGbOp.new(gear_id: gear_id, prereq: [create_gear_op._id.to_s],
                                  addtl_fs_gb: additional_filesystem_gb, saved_addtl_fs_gb: 0)

        track_usage_ops << TrackUsageOp.new(user_id: self.domain.owner._id, parent_user_id: self.domain.owner.parent_user_id,
                                            app_name: self.name, gear_id: gear_id, event: UsageRecord::EVENTS[:begin],
                                            usage_type: UsageRecord::USAGE_TYPES[:addtl_fs_gb],
                                            additional_filesystem_gb: additional_filesystem_gb, prereq: [ops.last._id.to_s])
      end

      gear_id_prereqs[gear_id] = register_dns_op._id.to_s
    end

    env_vars = self.domain.env_vars

    gear_id_prereqs.each_key do |gear_id|
      prereq = gear_id_prereqs[gear_id].nil? ? [] : [gear_id_prereqs[gear_id]]
      op = UpdateAppConfigOp.new(gear_id: gear_id, prereq: prereq, recalculate_sshkeys: true, add_env_vars: env_vars, config: (self.config || {}))
      ops << op
      update_app_config_op_id = op._id.to_s
      gear_id_prereqs[gear_id] = update_app_config_op_id
    end

    # Add broker auth for non scalable apps
    if app_dns_gear_id && !scalable
      prereq = gear_id_prereqs[app_dns_gear_id].nil? ? [] : [gear_id_prereqs[app_dns_gear_id]]
      ops << AddBrokerAuthKeyOp.new(gear_id: app_dns_gear_id, prereq: prereq)
    end

    # Add and/or push user env vars when this is not an app create or user_env_vars are specified
    user_vars_op_id = nil
    # FIXME this condition should be stronger (only fired when env vars are specified OR other gears already exist)
    # If this is a new group instance creation (gear creation and not a scale up), we can skip rollback
    if maybe_notify_app_create_op.empty? || user_env_vars.present?
      prereq = gear_id_prereqs[app_dns_gear_id].nil? ? [ops.last._id.to_s] : [gear_id_prereqs[app_dns_gear_id]]
      op = PatchUserEnvVarsOp.new(group_instance_id: ginst_id, user_env_vars: user_env_vars, push_vars: true,
                                  skip_rollback: !is_scale_up, prereq: prereq)
      ops << op
      user_vars_op_id = op._id.to_s
    end

    # Since this is a new gear creation, we can skip rollback for some operations
    prereq_op_id = prereq_op._id.to_s rescue nil
    add, usage = calculate_add_component_ops(gear_comp_specs, comp_spec_gears, ginst_id, deploy_gear_id, gear_id_prereqs, component_ops,
                                             is_scale_up, (user_vars_op_id || prereq_op_id), init_git_url,
                                             app_dns_gear_id, true)
    ops.concat(add)
    track_usage_ops.concat(usage)

    [ops, track_usage_ops]
  end

  def calculate_gear_destroy_ops(ginst_id, gear_ids, additional_filesystem_gb)
    pending_ops = []
    delete_gear_op = nil
    deleting_app = false
    gear_ids.each do |gear_id|
      deleting_app = true if self.gears.find(gear_id).app_dns
      destroy_gear_op = DestroyGearOp.new(gear_id: gear_id)
      deregister_sso_op = DeregisterSsoOp.new(gear_id: gear_id, prereq: [destroy_gear_op._id.to_s])
      deregister_dns_op = DeregisterDnsOp.new(gear_id: gear_id, prereq: [deregister_sso_op._id.to_s])
      unreserve_uid_op = UnreserveGearUidOp.new(gear_id: gear_id, prereq: [deregister_dns_op._id.to_s])
      delete_gear_op = DeleteGearOp.new(gear_id: gear_id, prereq: [unreserve_uid_op._id.to_s])
      track_usage_op = TrackUsageOp.new(user_id: self.domain.owner._id, parent_user_id: self.domain.owner.parent_user_id,
                          app_name: self.name, gear_id: gear_id, event: UsageRecord::EVENTS[:end],
                          usage_type: UsageRecord::USAGE_TYPES[:gear_usage],
                          prereq: [delete_gear_op._id.to_s])

      pending_ops.push(destroy_gear_op, deregister_sso_op, deregister_dns_op, unreserve_uid_op, delete_gear_op, track_usage_op)

      if additional_filesystem_gb != 0
        pending_ops <<  TrackUsageOp.new(user_id: self.domain.owner._id, parent_user_id: self.domain.owner.parent_user_id,
          app_name: self.name, gear_id: gear_id, event: UsageRecord::EVENTS[:end], usage_type: UsageRecord::USAGE_TYPES[:addtl_fs_gb],
          additional_filesystem_gb: additional_filesystem_gb,
          prereq: [delete_gear_op._id.to_s])
      end
    end

    self.group_instances.find(ginst_id).all_component_instances.each do |instance|
      if instance.cartridge.is_premium?
        gear_ids.each do |gear_id|
          pending_ops << TrackUsageOp.new(user_id: self.domain.owner._id, parent_user_id: self.domain.owner.parent_user_id,
            app_name: self.name, gear_id: gear_id, event: UsageRecord::EVENTS[:end], cart_name: instance.cartridge_name,
            usage_type: UsageRecord::USAGE_TYPES[:premium_cart],
            prereq: [delete_gear_op._id.to_s])
        end
      end
    end

    if deleting_app
      pending_ops << DeregisterRoutingDnsOp.new(prereq: [pending_ops.last._id.to_s]) if self.ha and Rails.configuration.openshift[:manage_ha_dns]
      pending_ops << NotifyAppDeleteOp.new(prereq: [pending_ops.last._id.to_s])
    end

    pending_ops
  end

  def get_sparse_scaledown_gears(ginst, scale_down_factor)
    scaled_gears = ginst.gears.select { |g| g.app_dns==false }
    sparse_components = ginst.all_component_instances.select(&:is_sparse?)
    gi_overrides = group_instances_with_overrides.select {|o| o.instance._id == ginst._id}
    specs ||= component_instances.map(&:to_component_spec)
    gears = []
    if sparse_components.length > 0
      (scale_down_factor...0).each do |i|
        # iterate through sparse components to see which ones need a definite scale-down
        surplus_sparse_components = sparse_components.select do |ci|
          comp_spec = nil
          gi_overrides.each {|o| o.components.each {|c| comp_spec = c if c.cartridge_name == ci.cartridge_name}}
          min = (comp_spec.min_gears rescue ci.get_component.scaling.min) || 1
          multiplier = comp_spec.multiplier rescue ci.get_component.scaling.multiplier
          cur_sparse_gears = ( ci.gears - gears.select {|g| g.component_instances.include?(ci)} ).count
          cur_total_gears = (ginst.gears - gears).count
          status = false
          if cur_sparse_gears <= min
            status = false
          # if the multiplier is nil, -1, 0, or 1, then any gears that are in addition to the minimum value can be removed
          elsif multiplier.nil? || multiplier <= 1
            status = true
          else
            # does removing a gear with this sparse cart still maintain the multiplier?
            # ensuring a float arithmetic to make correct comparisons
            status = (cur_total_gears -1) / ((cur_sparse_gears - 1) * 1.0) <= multiplier
          end
          status
        end
        # each of surplus_sparse_components want a gear removed that has them contained in the gear
        # if its empty, then remove a gear which does not have any of sparse_components in them (non-sparse gears)
        gear = nil
        if surplus_sparse_components.length > 0
          surplus_sparse_comp_ids = surplus_sparse_components.map(&:_id)
          # try to find a gear that has all the (and only those) sparse carts that need to be scaled down
          # doing a reverse on the gears list ensures that the last possible gear is picked for scaledown
          gear = scaled_gears.reverse.find { |g| g.sparse_carts.sort == surplus_sparse_comp_ids.sort }
          # if the above fails, try to find a gear that has sparse carts that are all part of those that need to be scaled down
          gear = scaled_gears.reverse.find { |g| g.sparse_carts.count > 0 && (g.sparse_carts - surplus_sparse_comp_ids).empty? } if gear.nil?
        end
        # if a gear is not found, just try to find one without any sparse carts
        gear = scaled_gears.reverse.find { |g| g.sparse_carts.empty? } if gear.nil?
        if gear.nil?
          # this may mean that some sparse_component's min limit is being violated
          raise OpenShift::UserException.new("Cannot scale down by #{scale_down_factor.abs} as it violates the minimum gear restrictions for sparse cartridges.")
        end
        gears << gear
        scaled_gears.delete(gear)
      end
    else
      gears = scaled_gears[(scaled_gears.length + scale_down_factor)..-1]
    end
    return gears
  end

  def add_sparse_cart?(index, sparse_carts_added_count, spec, is_scale_up)
    gears = sparse_carts_added_count
    total = index + 1
    if is_scale_up && (ci = self.find_component_instance_for(spec) rescue nil)
      gears += ci.gears.length
      total += ci.group_instance.gears.length
    end

    comp = spec.component
    unless comp.is_sparse?
      max = (spec.respond_to?(:max_gears) ? spec.max_gears : comp.scaling.max) || -1
      return max == -1 || total <= max
    end

    multiplier = (spec.multiplier rescue comp.scaling.multiplier) || 0
    min = (spec.min_gears rescue comp.scaling.min) || 1
    max = (spec.max_gears rescue comp.scaling.max) || -1

    # check on min first
    return true if gears < min

    # if min is met, but multiplier is infinite, return false
    return false if multiplier <= 0

    # for max, and cases where multiplier has been changed in apps mid-life
    multiplier_gears = ( total / ( multiplier * 1.0 ) ).ceil
    should_be_sparse_cart_count = [multiplier_gears, (max == -1 ? multiplier_gears : max)].min
    return true if gears < should_be_sparse_cart_count

    false
  end

  def calculate_add_component_ops(gear_comp_specs, comp_spec_gears, group_instance_id, deploy_gear_id,
                                  gear_id_prereqs, component_ops, is_scale_up, prereq_id, init_git_url=nil,
                                  app_dns_gear_id=nil, is_gear_creation=false)
    ops = []
    usage_ops = []

    comp_spec_gears.keys.each do |comp_spec|
      component_ops[comp_spec] = {new_component: nil, adds: [], post_configures: [], add_broker_auth_keys: []} if component_ops[comp_spec].nil?
      cartridge = comp_spec.cartridge

      new_component_op_id = []
      if self.group_instances.where(_id: group_instance_id).exists? and (not is_scale_up)
        new_component_op = NewCompOp.new(
          group_instance_id: group_instance_id,
          comp_spec: comp_spec,
          cartridge_vendor: cartridge.cartridge_vendor, #remove after sprint 40
          version: cartridge.version,                   #remove after sprint 40
        )
        new_component_op.prereq = [prereq_id] unless prereq_id.nil?
        component_ops[comp_spec][:new_component] = new_component_op
        new_component_op_id = [new_component_op._id.to_s]
        ops << new_component_op
      end

      #sparse_carts_added_count = 0
      #gear_id_prereqs.each_with_index do |prereq, index|
      comp_spec_gears[comp_spec].each do |gear_id|
        #gear_id, prereq_id = prereq
        prereq_id = gear_id_prereqs[gear_id]
        #next if not add_sparse_cart?(index, sparse_carts_added_count, comp_spec, is_scale_up)
        #sparse_carts_added_count += 1

        # Ensure that all web_proxies get broker auth
        if cartridge.is_web_proxy?
          add_broker_auth_op = AddBrokerAuthKeyOp.new(gear_id: gear_id, prereq: new_component_op_id + [prereq_id])
          prereq_id = add_broker_auth_op._id.to_s
          component_ops[comp_spec][:add_broker_auth_keys] << add_broker_auth_op
          ops << add_broker_auth_op
        end

        git_url = nil

        if gear_id == deploy_gear_id and needs_git_url?(cartridge)
          git_url = init_git_url
        end

        add_component_op = AddCompOp.new(gear_id: gear_id, comp_spec: comp_spec, init_git_url: git_url,
                                         skip_rollback: is_gear_creation, prereq: new_component_op_id + [prereq_id])
        ops << add_component_op
        component_ops[comp_spec][:adds] << add_component_op
        usage_op_prereq = [add_component_op._id.to_s]

        # if this is a web_proxy, send any existing alias and SSL cert information to it
        if cartridge.is_web_proxy? and self.aliases.present?
          resend_aliases_op = ResendAliasesOp.new(gear_id: gear_id, fqdns: self.aliases.map {|app_alias| app_alias.fqdn},
                                                  skip_rollback: is_gear_creation, prereq: [add_component_op._id.to_s])
          ops.push resend_aliases_op

          aliases_with_certs = self.aliases.select {|app_alias| app_alias.has_private_ssl_certificate}
          if aliases_with_certs.present?
            resend_ssl_certs_op = ResendSslCertsOp.new(gear_id: gear_id, ssl_certs: get_ssl_certs(),
                                                       skip_rollback: is_gear_creation, prereq: [resend_aliases_op._id.to_s])
            ops.push resend_ssl_certs_op
          end
        end

        # in case of deployable carts, the post-configure op is executed at the end
        # to ensure this, it is removed from the prerequisite list for any other pending_op
        # to avoid issues, pending_ops should not depend ONLY on post-configure op to manage execution order
        post_configure_op = nil
        unless (gear_id != app_dns_gear_id) and cartridge.is_deployable?
          post_configure_op = PostConfigureCompOp.new(gear_id: gear_id, comp_spec: comp_spec, init_git_url: git_url, prereq: [add_component_op._id.to_s] + [prereq_id])
          ops << post_configure_op
          component_ops[comp_spec][:post_configures] << post_configure_op
          usage_op_prereq += [post_configure_op._id.to_s]
        end

        if cartridge.is_premium?
          usage_ops << TrackUsageOp.new(user_id: self.domain.owner._id, parent_user_id: self.domain.owner.parent_user_id,
            app_name: self.name, gear_id: gear_id, event: UsageRecord::EVENTS[:begin], cart_name: cartridge.name,
            usage_type: UsageRecord::USAGE_TYPES[:premium_cart], prereq: usage_op_prereq)
        end
      end
    end

    [ops, usage_ops]
  end

  def calculate_remove_component_ops(comp_specs)
    ops = []
    comp_specs.each do |comp_spec|
      component_instance = find_component_instance_for(comp_spec)
      cartridge = comp_spec.cartridge

      if component_instance.is_plugin? || (!self.scalable && component_instance.is_embeddable?)
        component_instance.gears.each do |gear|
          ops << RemoveCompOp.new(gear_id: gear._id, comp_spec: comp_spec)
          if cartridge.is_premium?
            ops << TrackUsageOp.new(user_id: self.domain.owner._id, parent_user_id: self.domain.owner.parent_user_id,
              app_name: self.name, gear_id: gear._id.to_s, event: UsageRecord::EVENTS[:end], cart_name: cartridge.name,
              usage_type: UsageRecord::USAGE_TYPES[:premium_cart], prereq: [ops.last._id.to_s])
          end
        end
      end
      ops << DeleteCompOp.new(comp_spec: comp_spec, prereq: ops.map{|o| o._id.to_s})
      ops << UnsubscribeConnectionsOp.new(sub_pub_info: get_unsubscribe_info(component_instance), prereq: [ops.last._id.to_s])
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
  def calculate_ops(changes, moves=[], connections=nil, group_overrides=nil, init_git_url=nil, user_env_vars=nil, region_id=nil)
    add_gears = 0
    remove_gears = 0
    pending_ops = []
    begin_usage_ops = []

    overrides = GroupOverride.remove_defaults_from(group_overrides, 1, -1, default_gear_size, 0)

    # we are not comparing the old and new group overrides since it ignores the multiplier
    # refer bug for details --> https://bugzilla.redhat.com/show_bug.cgi?id=1123371
    pending_ops << SetGroupOverridesOp.new(group_overrides: overrides,
                                           saved_group_overrides: self.group_overrides,
                                           pre_save: !self.persisted?)
    prereq_op = pending_ops.last

    deploy_gear_id = nil
    component_ops = {}

    # Create group instances and gears in preparation for move or add component operations
    changes.select(&:new?).each do |change|
      if change.gear_change < 1
        change.added.each do |spec|
          pending_ops << NewCompOp.new(
            group_instance_id: change.to_instance_id,
            comp_spec: spec,
            prereq: [prereq_op].compact.map(&:_id),
          )
          (component_ops[spec] ||= {})[:new_component] = pending_ops.last
        end
        next
      end

      add_gears += change.gear_change
      gear_size = change.to.gear_size
      additional_filesystem_gb = change.to.additional_filesystem_gb

      gear_ids = Array.new(change.gear_change){ |i| Moped::BSON::ObjectId.new.to_s }
      app_dns = change.will_have_app_dns?(self)
      deploy_gear_id = if app_dns
        gear_ids[0] = self._id.to_s
      end

      ops, usage_ops = calculate_gear_create_ops(change.to_instance_id.to_s, gear_ids, deploy_gear_id, change.added, component_ops, additional_filesystem_gb,
                                      gear_size, prereq_op, false, app_dns, init_git_url, user_env_vars, region_id)
      pending_ops.concat(ops)
      begin_usage_ops.concat(usage_ops)
    end

    moves.each do |move|
      #ops << PendingAppOps.new(op_type: :move_component, args: move, flag_req_change: true)
    end

    if user_env_vars.present? && changes.any?{ |c| c.existing? && c.added? }
      pending_ops << PatchUserEnvVarsOp.new(user_env_vars: user_env_vars)
    end

    if upgrades = changes.inject([]){ |a, c| a.concat(c.upgraded); a }.presence
      pending_ops << UpdateCompIds.new(
        comp_specs: upgrades.map(&:last),
        saved_comp_specs: upgrades.map(&:first),
        prereq: [(pending_ops.last._id.to_s rescue nil)].compact.presence
      )
    end

    prereq_op_id = pending_ops.last._id.to_s rescue nil

    changes.each do |change|
      if change.existing?
        group_instance = change.from.instance

        if change.delete?
          remove_gears += -change.gear_change
          additional_filesystem_gb = change.from.additional_filesystem_gb
          group_instance_remove_ops = calculate_remove_group_instance_ops(change.removed, group_instance, additional_filesystem_gb)
          pending_ops.concat(group_instance_remove_ops)

        else
          deploy_gear_id =
            if app_dns_gear = group_instance.application_dns_gear
              app_dns_gear._id.to_s
            end

          if change.removed?
            ops = calculate_remove_component_ops(change.removed)
            pending_ops.concat(ops)
          end

          if change.from.gear_size != change.to.gear_size
            raise OpenShift::UserException.new("Incompatible gear sizes: #{change.from.gear_size} and #{change.to.gear_size} for cartridges #{change.to.components.map(&:name).uniq.to_sentence} that will reside on the same gear.", 142)
          end

          if change.added?
            gear_id_prereqs = {}
            gear_comp_specs = {}
            comp_spec_gears = {}
            change.added.each do |cs|
              sparse_carts_added_count = 0
              group_instance.gears.each_with_index do |g, i|
                gear_id_prereqs[g._id.to_s] = [] unless gear_id_prereqs[g._id.to_s]
                gear_comp_specs[g._id.to_s] = [] unless gear_comp_specs[g._id.to_s]
                comp_spec_gears[cs] = [] unless comp_spec_gears[cs]

                if add_sparse_cart?(i, sparse_carts_added_count, cs, false)
                  gear_comp_specs[g._id.to_s].concat change.added
                  comp_spec_gears[cs] << g._id.to_s
                  sparse_carts_added_count += 1
                end
              end
            end

            ops, usage_ops = calculate_add_component_ops(gear_comp_specs, comp_spec_gears, change.existing_instance_id.to_s, deploy_gear_id, gear_id_prereqs, component_ops, false, prereq_op_id, nil)
            pending_ops.concat(ops)
            begin_usage_ops.concat(usage_ops)
          end

          changed_additional_filesystem_gb = nil
          #add/remove fs space from existing gears
          if change.additional_filesystem_change != 0
            new_fs = change.to.additional_filesystem_gb
            old_fs = change.from.additional_filesystem_gb
            changed_additional_filesystem_gb = new_fs
            fs_prereq = []
            fs_prereq = [pending_ops.last._id.to_s] if pending_ops.last
            end_usage_op_ids = []

            if old_fs != 0
              group_instance.gears.each do |gear|
                pending_ops << TrackUsageOp.new(
                  user_id: self.domain.owner._id, parent_user_id: self.domain.owner.parent_user_id,
                  app_name: self.name, gear_id: gear._id.to_s, event: UsageRecord::EVENTS[:end],
                  usage_type: UsageRecord::USAGE_TYPES[:addtl_fs_gb],
                  additional_filesystem_gb: old_fs,
                  prereq: fs_prereq)
                end_usage_op_ids << pending_ops.last._id.to_s
              end
            end

            pending_ops << ChangeAddtlFsGbOp.new(
              group_instance_id: group_instance._id,
              addtl_fs_gb: new_fs,
              saved_addtl_fs_gb: old_fs,
              prereq: (end_usage_op_ids.empty? ? fs_prereq : end_usage_op_ids),
            )
            change_op_id = pending_ops.last._id.to_s

            group_instance.gears.each do |gear|
              pending_ops << SetAddtlFsGbOp.new(
                  gear_id: gear._id.to_s,
                  addtl_fs_gb: new_fs,
                  saved_addtl_fs_gb: old_fs,
                  prereq: [change_op_id])

              if new_fs != 0
                begin_usage_ops << TrackUsageOp.new(
                  user_id: self.domain.owner._id, parent_user_id: self.domain.owner.parent_user_id,
                  app_name: self.name, gear_id: gear._id.to_s, event: UsageRecord::EVENTS[:begin],
                  usage_type: UsageRecord::USAGE_TYPES[:addtl_fs_gb],
                  additional_filesystem_gb: new_fs,
                  prereq: [pending_ops.last._id.to_s])
              end
            end
          end

          scale_change = change.gear_change
          if scale_change > 0
            add_gears += scale_change
            gear_ids = Array.new(scale_change){ |i| Moped::BSON::ObjectId.new.to_s }

            ops, usage_ops = calculate_gear_create_ops(
                    change.existing_instance_id.to_s,
                    gear_ids,
                    deploy_gear_id,
                    change.to.components,
                    component_ops,
                    change.to.additional_filesystem_gb,
                    change.to.gear_size,
                    nil, true, false, nil,
                    user_env_vars)
            pending_ops.concat(ops)
            begin_usage_ops.concat(usage_ops)

          elsif scale_change < 0
            remove_gears += -scale_change
            group = change.from.instance
            gears = get_sparse_scaledown_gears(group, scale_change)
            remove_ids = gears.map{ |g| g._id.to_s }
            ops = calculate_gear_destroy_ops(change.existing_instance_id.to_s, remove_ids, change.from.additional_filesystem_gb)
            pending_ops.concat(ops)
          end
        end
      end
    end

    config_order = calculate_configure_order(component_ops.keys)

    config_order.each_index do |idx|
      next if idx == 0
      prereq_ids = []
      prereq_ids += (component_ops[config_order[idx-1]][:add_broker_auth_keys] || []).map{|op| op._id.to_s}
      prereq_ids += (component_ops[config_order[idx-1]][:adds] || []).map{|op| op._id.to_s}

      component_ops[config_order[idx]][:new_component].prereq += prereq_ids unless component_ops[config_order[idx]][:new_component].nil?
      (component_ops[config_order[idx]][:add_broker_auth_keys] || []).each { |op| op.prereq += prereq_ids }
      (component_ops[config_order[idx]][:adds] || []).each { |op| op.prereq += prereq_ids }
    end

    if pending_ops.present? and pending_ops.any?{|op| op.reexecute_connections?}.present?
      # set all ops as the pre-requisite for execute connections except post_configure ops
      # FIXME: this could be arbitrarily large
      all_ops_ids = pending_ops.map{ |op| op._id.to_s }.compact
      execute_connection_op = ExecuteConnectionsOp.new(prereq: all_ops_ids)
      pending_ops << execute_connection_op
    end

    post_config_order = calculate_post_configure_order(component_ops.keys)
    post_config_order.each_index do |idx|
      cur_spec = post_config_order[idx]

      # if this is a deployable cart being configured,
      # then make sure that the post-configure op for it is executed after execute_connections
      # also, it should not be the prerequisite for any other pending_op
      if cur_spec.cartridge.is_deployable?
        component_ops[cur_spec][:post_configures].each do |pcop|
          pcop.prereq += [execute_connection_op._id.to_s]
          pending_ops.each{ |op| op.prereq.delete_if { |prereq_id| prereq_id == pcop._id.to_s } }
        end
      end

      next if idx == 0

      prev_spec = post_config_order[idx - 1]
      prereq_ids = []
      prereq_ids += (component_ops[prev_spec][:post_configures] || []).map{|op| op._id.to_s}
      (component_ops[cur_spec][:post_configures] || []).each { |op| op.prereq += prereq_ids }
    end

    # update-cluster has to run after all deployable carts have been post-configured
    if scalable && pending_ops.present? && !(pending_ops.length == 1 and SetGroupOverridesOp === pending_ops.first)
      all_ops_ids = pending_ops.map{ |op| op._id.to_s }
      pending_ops << UpdateClusterOp.new(prereq: all_ops_ids)
    end

    # notify subscribers of route changes if endpoints are exposed
    # FIXME routing publish should be transactional
    # if pending_ops.present? && (ops = component_ops.inject([]){ |p,(_,v)| p.concat((v[:expose_ports] || [])) }).presence
    #   ops.each do |op|
    #     pending_ops << PublishRoutingInfoOp.new(gear_id: op.gear_id, prereq: [op._id.to_s])
    #   end
    # end

    # track begin usage ops after update-cluster/execute-connections op
    if begin_usage_ops.present?
      begin_usage_prereq = []
      begin_usage_prereq << pending_ops.last._id.to_s if pending_ops.present?
      begin_usage_ops.each{ |op| op.prereq.concat(begin_usage_prereq) }
      pending_ops.concat(begin_usage_ops)
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
  def compute_diffs(existing, added, upgrades)
    return [[GroupChange.new(existing.first, added.first, upgrades.slice(*existing.first))], []] if existing.length == 1 && added.length == 1

    total = existing.length + added.length - 1
    costs = Matrix.build(total+1, total+1){0}
    #compute cost of moves
    (0..total).each do |from|
      (0..total).each do |to|
        costs[from,to] =
          if f = existing[from]
            if t = added[to]
              updated = f.components.map{ |c| upgrades[c] || c }
              (t.components-updated).length + (updated-t.components).length
            else
              f.components.length
            end
          else
            (t = added[to]) ? t.components.length : 0
          end
      end
    end

    changes = []
    (0..total).each do |from|
      to = costs.row_vectors[from].to_a.index(costs.row_vectors[from].min)
      f = existing[from]
      t = added[to]
      if (f && f.components.present?) || (t && t.components.present?)
        changes << GroupChange.new(f, t, upgrades.slice(*f))
      end

      (0..total).each {|i| costs[i,to] = 1000 }
    end

    moves = GroupChange.moves(changes)

    [changes, moves]
  end

  # Creates array of subscriptions from component instance and
  # publishers which accounts for subscriptions as specified and
  # calculated subscriptions for connections with "wildcard" ENV:*
  # subscriptions in manifest
  #
  # == Parameters:
  # ci::
  #   A component instance as representation as generated by elaborate
  # publishers::
  #   A hash of publishers for the set of features provided to
  #   elaborate
  #
  # == Returns:
  # subscriptions::
  #   An array of OpenShift::Connector object copies with
  #   subscriptions properly realized
  #
  def subscription_filter(ci, publishers)
    component = ci.component
    wildcards = component.subscribes.select { |connector| connector.type == "ENV:*" }
    raise "Multiple wildcard subscriptions specified in component #{component.name}" if wildcards.size > 1

    subscriptions = component.subscribes.map do |conn|
      new_conn = nil
      # Avoid copying ENV: connectors if wildcard subscription is found
      if not ( conn.name.start_with? "ENV:" and wildcards.any? )
        new_conn = OpenShift::Connector.new(conn.name)
        new_conn.from_descriptor(conn.to_descriptor)
      end
      new_conn
    end.compact

    # Add all published "ENV:" connections for subscriber with wildcard
    if wildcards.any?
      connector = wildcards[0]
      publishers.keys.each do |ptype|
        if ptype.start_with? "ENV:"
          new_conn = OpenShift::Connector.new(connector.name)
          new_conn.type = ptype
          new_conn.required = connector.required
          subscriptions << new_conn
        end
      end
    end
    subscriptions
  end

  # Computes the group instances, component instances and connections required to support a given set of features
  #
  # == Parameters:
  # feature::
  #   A list of artridge instances
  # group_overrides::
  #   A list of group-overrides which specify which components must be placed on the same group.
  #   Components can be specified as Hash{cart: <cart name> [, comp: <component name>]}
  #
  # == Returns:
  # connections::
  #   An array of connections
  # group instances::
  #   An array of hash values representing a group instances.
  def elaborate(cartridges, group_overrides=[])
    # All of the components that will be installed
    specs = component_specs_from(cartridges)

    # add overrides that are part of the application
    overrides = implicit_application_overrides(specs)

    # use a new set of group overrides
    overrides.concat(group_overrides)

    overrides = split_platform_overrides(overrides)

    # Calculate connections and add any shared placement rules
    connections, connection_overrides = connections_from_component_specs(specs)
    overrides.concat(connection_overrides)

    groups = GroupOverride.reduce(overrides, specs).each do |o|
      # force consistent defaults on every group
      o.defaults(1, -1, self.default_gear_size, 0)
    end

    [connections, groups]
  end

  # Replaces group overrides that contain components with more than one platform
  #
  # == Parameters:
  # overrides::
  #   An array of GroupOverride instances
  #
  # == Returns:
  #   An array of GroupOverride instances that do not contain components with more that one platform.
  def split_platform_overrides(overrides)
    return overrides unless overrides
    split_overrides = []

    overrides.each do |group_override|
      next unless group_override

      # only allow grouping if we're working with a single platform
      if group_override.components.map {|c| c.cartridge.platform rescue nil }.compact.uniq.count > 1
        group_override.components.each do |c|
          split_overrides << GroupOverride.new([c], group_override.min_gears, group_override.max_gears,
                                               group_override.gear_size, group_override.additional_filesystem_gb).implicit
        end
      else
        split_overrides << group_override
      end
    end

    split_overrides
  end

  def component_specs_from(cartridges)
    # All of the components that will be available
    specs = []
    cartridges.each do |cart|
      cart.components.each do |component|
        specs << ComponentSpec.for_model(component, cart, self)
      end
    end
    specs
  end

  def add_required_dependencies(cartridges)
    all = [].concat(cartridges)
    added = [].concat(cartridges)
    depth = 0
    begin
      process = added
      added = []
      process.each do |cart|
        (cart.requires).each do |required|
          satisfied = Array(required).any? do |feature|
            all.any?{ |d| d.features.include?(feature) || d.names.include?(feature) }
          end
          if !satisfied
            Array(required).any? do |feature|
              if located = CartridgeCache.find_cartridge_by_base_name(feature, self)
                all << located
                added << located
                true
              end
            end or raise OpenShift::UnfulfilledRequirementException.new(required, cart.name)
          end
        end
      end
      if (depth += 1) > MAX_CARTRIDGE_RECURSION
        raise OpenShift::UserException.new("Too much recursion on cartridge dependency processing.")
      end
    end while added.present?
    all
  end

  def self.only_satisfied_dependencies(cartridges, raise_on_failure=false)
    all = [].concat(cartridges)
    changed = false
    begin
      changed = all.select! do |cart|
        cart.requires.all? do |required|
          located = nil
          Array(required).each do |feature|
            if all.any?{ |d| d.features.include?(feature) || d.names.include?(feature) }
              located = true
              break
            end
          end
          raise OpenShift::UnfulfilledRequirementException.new(required, cart.name) if !located && raise_on_failure
          located
        end
      end
    end while changed && all.present?
    all
  end

  def connections_from_component_specs(specs)
    overrides = []

    #calculate connections
    publishers = {}
    connections = []
    specs.each do |spec|
      spec.component.publishes.each do |connector|
        type = connector.type
        name = connector.name
        publishers[type] = [] if publishers[type].nil?
        publishers[type] << { spec: spec, connector: name }
      end
    end

    specs.each do |spec|
      # obtain copy of connections with fully-resolved subscriptions for this ci
      subscriptions = subscription_filter(spec, publishers)
      subscriptions.each do |connector|
        stype = connector.type
        sname = connector.name

        if publishers.has_key? stype
          publishers[stype].each do |cinfo|
            connections << {
              "from_comp_inst" => cinfo[:spec],
              "to_comp_inst" =>   spec,
              "from_connector_name" => cinfo[:connector],
              "to_connector_name" =>   sname,
              "connection_type" =>     stype}
            if stype.starts_with?("FILESYSTEM") or stype.starts_with?("SHMEM")
              overrides << [cinfo[:spec], spec]
            end
          end
        end
      end
    end
    [connections, overrides]
  end


  def enforce_system_order(order, categories)
    web_carts = Array(categories['web_framework'])
    service_carts = Array(categories['service']) - web_carts
    other_carts = categories.map { |k,v| Array(v) }.flatten - web_carts - service_carts

    web_carts.each do |w|
      (service_carts + other_carts).each do |so|
        order.add_component_order([w, so])
      end
    end
    service_carts.each do |s|
      other_carts.each do |o|
        order.add_component_order([s, o])
      end
    end
  end

  # Returns the configure order specified in the application descriptor or processes the configure
  # orders for each component and returns the final order (topological sort).
  # @note This is calculates separately from start/stop order as this function is usually used to
  #   compute the {PendingAppOps} while start/stop order applies to already configured components.
  #
  # == Parameters:
  # comp_specs::
  #   Array of components specs to order.
  #
  # == Returns:
  # {ComponentInstance} objects ordered by calculated configure order
  def calculate_configure_order(specs)
    configure_order = ComponentOrder.new

    specs.each{ |spec| configure_order.add_component_order([spec]) }

    #use the map to build DAG for order calculation
    specs.each do |spec|
      order = []
      spec.cartridge.configure_order.each do |deps|
        # does an existing cartridge satisfy the order requirement
        next if Array(deps).any?{ |name| self.component_instances.any?{ |i| i.cartridge.names.include?(name) || i.cartridge.categories.include?(name) } }

        # does a newly installed cartridge satisfy the order requirement
        match = false
        Array(deps).each do |name|
          if match = specs.detect{ |i| i.cartridge.names.include?(name) } || specs.detect{ |i| i.cartridge.categories.include?(name) }
            break
          end
        end

        # check if any platform cartridge can satisfy the dependency
        # if so, include them in the message being sent back to the user
        error_message = "Cartridge '#{spec.cartridge_name}' can not be added without #{Array(deps).join(' or ')}."
        platform_carts = CartridgeCache.get_all_cartridges
        Array(deps).each do |name|
          matching_carts = platform_carts.select { |cart| cart.names.include?(name) || cart.categories.include?(name) }
          error_message += " The dependency '#{name}' can be satisfied with #{matching_carts.map(&:name).join(' or ')}." if matching_carts.present?
        end

        raise OpenShift::UserException.new(error_message, 185) if !match
        order << match
      end
      next if order.empty?
      configure_order.add_component_order(order)
    end

    categories = {}
    specs.each do |spec|
      cats = spec.cartridge.categories
      ['web_framework', 'plugin', 'service', 'embedded', 'ci_builder', 'web_proxy', 'external'].each do |cat|
        (categories[cat] ||= []) << spec if cats.include?(cat)
      end
    end

    # enforce system order of components (web_framework first etc)
    enforce_system_order(configure_order, categories)

    #calculate configure order using tsort
    begin
      computed_configure_order = configure_order.tsort
    rescue
      raise OpenShift::UserException.new("Conflict in calculating configure order. Cartridges should adhere to system's order ('web_framework','service','plugin').", 109)
    end

    # configure order can have nil if the component is already configured
    # for eg, phpmyadmin is being added and it is the only component being passed/added
    # this could happen if mysql is already previously configured
    computed_configure_order.compact
  end

  def calculate_post_configure_order(specs)
    configure_order = calculate_configure_order(specs)
    configure_order.select {|spec| !spec.cartridge.is_web_framework?} + configure_order.select {|spec| spec.cartridge.is_web_framework?}
  end

  # Returns the start/stop order by processing the start and stop
  # orders for each component and returns the final order (topological sort).
  #
  # == Returns:
  # start_order::
  #   {ComponentInstance} objects ordered using post-configure order
  # stop_order::
  #   {ComponentInstance} objects ordered using reverse of post-configure order
  def calculate_component_orders
    start_order = calculate_post_configure_order(self.component_instances)
    stop_order = start_order.reverse

    [start_order, stop_order]
  end

  def get_ssl_certs(fqdns=[])
    # get all the SSL certs from the HAProxy DNS gear
    haproxy_gears = self.gears.select { |g| g.component_instances.select { |ci| ci.get_cartridge.is_web_proxy? }.present? }
    dns_haproxy_gear = haproxy_gears.select { |g| g.app_dns }.first
    certs = dns_haproxy_gear.get_all_ssl_certs()

    # if the certs are not avaialble on the dns haproxy gear, make another check on a different haproxy gear
    if certs.blank?
      non_dns_haproxy_gears = haproxy_gears.select { |g| !g.app_dns }
      non_dns_haproxy_gears.each do |g|
        certs = g.get_all_ssl_certs()
        break if certs.present?
      end
    end

    # if SSL certs are still not received, log this as an error, but continue
    Rails.logger.error "SSL certificate information not received from haproxy gears for application #{application.canonical_name}" if certs.blank?

    # send the SSL certs for the specified aliases to the gear
    certs.select { |cert_info| fqdns.blank? or fqdns.include? cert_info[2] }
  end

  def get_all_updated_ssh_keys
    ssh_keys = []
    ssh_keys = self.app_ssh_keys.map {|k| k.as_document } # the app_ssh_keys already have their name "updated"
    ssh_keys |= get_updated_ssh_keys(self.domain.system_ssh_keys)
    ssh_keys |= CloudUser.members_of(self){ |m| Ability.has_permission?(m._id, :ssh_to_gears, Application, m.role, self) }.map{ |u| get_updated_ssh_keys(u.ssh_keys) }.flatten(1)

    ssh_keys
  end

  # The ssh key names are used as part of the ssh key comments on the application's gears
  # Do not change the format of the key name, otherwise it may break key removal code on the node
  #
  # FIXME why are we not using uuids and hashes to guarantee key uniqueness on the nodes?
  #
  def get_updated_ssh_keys(keys)
    updated_keys_attrs = []
    keys.flatten.each do |key|
      key_attrs = key.as_document.deep_dup
      case key.class
      when UserSshKey
        key_attrs["name"] = key.cloud_user._id.to_s + "-" + key_attrs["name"]
        key_attrs["login"] = key.cloud_user.login
      when SystemSshKey
        key_attrs["name"] = "domain-" + key_attrs["name"]
      when ApplicationSshKey
        key_attrs["name"] = "application-" + key_attrs["name"]
      end
      updated_keys_attrs.push(key_attrs)
    end
    updated_keys_attrs
  end

  # Get path for checking application health
  # This method is only to maintain backwards compatibility for rest api version 1.0
  # @return [String]
  def health_check_path
    page = 'health'
  end

  # Get scaling limits for the application's group instance that has the web framework cartridge
  # This method is only to maintain backwards compatibility for rest api version 1.0
  # @return [Integer, Integer]
  def get_app_scaling_limits
    web_cart = web_cartridge or return [1, 1]
    component_instance = self.component_instances.find_by(cartridge_name: web_cart.name)
    group_instance = group_instances_with_overrides.detect{ |i| i.instance.all_component_instances.include? component_instance }
    [group_instance.min_gears, group_instance.max_gears]
  end

  def self.validate_user_env_variables(user_env_vars, no_delete=false)
    if user_env_vars.present?
      if !user_env_vars.is_a?(Array) or !user_env_vars[0].is_a?(Hash)
        raise OpenShift::UserException.new("Invalid environment variables: expected array of hashes", 186, "environment_variables")
      end
      keys = {}
      user_env_vars.each do |ev|
        name = ev['name']
        value = ev['value']
        unless name and (ev.keys - ['name', 'value']).empty?
          raise OpenShift::UserException.new("Invalid environment variable #{ev}. Valid keys 'name'(required), 'value'", 186, "environment_variables")
        end
        raise OpenShift::UserException.new("Invalid environment variable name #{name}: specified multiple times", 188, "environment_variables") if keys[name]
        keys[name] = true
        raise OpenShift::UserException.new("Name must be 128 characters or less.", 188, "environment_variables") if name.length > 128
        match = /\A([a-zA-Z_][\w]*)\z/.match(name)
        raise OpenShift::UserException.new("Name can only contain letters, digits and underscore and can't begin with a digit.", 188, "environment_variables") if match.nil?
        raise OpenShift::UserException.new("Value must be 512 characters or less.", 190, "environment_variables") if value and value.length > 512
        raise OpenShift::UserException.new("Value cannot contain null characters.", 190, "environment_variables") if value and value.include? "\\000"
      end
      if no_delete
        set_vars, unset_vars = sanitize_user_env_variables(user_env_vars)
        raise OpenShift::UserException.new("Environment variable deletion not allowed for this operation", 186, "environment_variables") unless unset_vars.empty?
      end
    end
  end

  def self.sanitize_user_env_variables(user_env_vars)
    set_vars = []
    unset_vars = []
    if user_env_vars.present?
      # separate add/update and delete user env vars
      user_env_vars.each do |ev|
        if ev['name'] && ev['value']
          set_vars << ev
        else
          unset_vars << ev
        end
      end
    end
    return set_vars, unset_vars
  end

  def validate_certificate(ssl_certificate, private_key, pass_phrase)
    if ssl_certificate.present?
      raise OpenShift::UserException.new("Private key is required", 172, "private_key") if private_key.nil?
      #validate certificate
      begin
        ssl_cert_clean = OpenSSL::X509::Certificate.new(ssl_certificate.strip)
      rescue Exception => e
        raise OpenShift::UserException.new("Invalid certificate: #{e.message}", 174, "ssl_certificate")
      end
      #validate private key
      begin
        pass_phrase = '' if pass_phrase.nil?
        priv_key_clean = OpenSSL::PKey.read(private_key.strip, pass_phrase.strip)
      rescue Exception => e
        raise OpenShift::UserException.new("Invalid private key or pass phrase: #{e.message}", 172, "private_key")
      end
      if not ssl_cert_clean.check_private_key(priv_key_clean)
        raise OpenShift::UserException.new("Private key/certificate mismatch", 172, "private_key")
      end

      if not [OpenSSL::PKey::RSA, OpenSSL::PKey::DSA].include?(priv_key_clean.class)
        raise OpenShift::UserException.new("Key must be RSA or DSA for Apache mod_ssl",172, "private_key")
      end
    end
  end

  def deploy(hot_deploy=false, force_clean_build=false, ref=nil, artifact_url=nil)
    result_io = ResultIO.new
    Lock.run_in_app_lock(self) do
      op_group = DeployOpGroup.new(hot_deploy: hot_deploy, force_clean_build: force_clean_build, ref: ref, artifact_url: artifact_url)
      self.pending_op_groups << op_group
      self.run_jobs(result_io)
    end
    return result_io
  end

  def activate(deployment_id)
    deployment = self.deployments.find_by(deployment_id: deployment_id)
    result_io = ResultIO.new
    Lock.run_in_app_lock(self) do
      op_group = ActivateOpGroup.new(deployment_id: deployment_id)
      self.pending_op_groups << op_group
      self.run_jobs(result_io)
    end
    return result_io
  end

  def refresh_deployments()
    #TODO call node to get the latest deployments
  end

  def update_deployments(deployments)
    # validate the deployments
    deployments.each { |d| raise OpenShift::ApplicationValidationException.new(self) unless d.valid? }

    self.set(:deployments, deployments.map{|d| d.to_hash})
  end

  def update_deployments_from_result(result_io)
    if result_io.deployments
      deploys = []
      result_io.deployments.each do |d|
        deploys.push(Deployment.new(deployment_id: d[:id],
                                       created_at: Time.at(d[:created_at].to_f),
                                              ref: d[:ref],
                                             sha1: d[:sha1],
                                     artifact_url: d[:artifact_url],
                                      activations: d[:activations] ? d[:activations].map(&:to_f) : [],
                                       hot_deploy: d[:hot_deploy] || false,
                                force_clean_build: d[:force_clean_build] || false))
      end
      update_deployments(deploys)
    end
  end

  private
    ##
    # Return all of the group overrides persisted on the application. These
    # overrides are mutable.  Use application_overrides when you need to
    # see the effective overrides.
    #
    # Does not reflect any persisted settings on the instances - so will not have
    # additional_filesystem_gb or gear_size set.
    #
    def group_instance_overrides
      group_instances.map{ |g| GroupOverride.for_instance(g) }
    end

    def compute_upgrades(replacements)
      return {} if replacements.blank?
      replacements.inject({}) do |h, (f, t)|
        raise OpenShift::UserException.new("Cartridges with more than one component cannot be replaced.") if f.components.length != 1
        raise OpenShift::UserException.new("Replacing #{f.name} with #{t.name} is not supported because they have different configurations.") if t.components.length != 1
        h[ComponentSpec.for_model(f.components.first, f)] = ComponentSpec.for_model(t.components.first, t)
        h
      end
    end

    def needs_git_url?(cartridge)
      # we need the template git url for the component if the cartridge is deployable
      # or if we have a standalone web cartridge
      is_standalone_web_proxy = (cartridge.is_web_proxy? and !self.is_collocatable?)
      (cartridge.is_deployable? or is_standalone_web_proxy)
    end
end
