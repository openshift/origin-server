# Represents a gear created on an OpenShift Origin Node.
# @!attribute [r] application
#   @return [Application] that this {Gear} is part of.
# @!attribute [r] group_instance_id
#   @return [Moped::BSON::ObjectId] Reference to the {GroupInstance} that this gear is part of.
# @!attribute [r] server_identity
#   @return [String] DNS name of the node the gear is hosted on.
# @!attribute [r] uid
#   @return [Integer] UID of the user on the node.
# @!attribute [r] name
#   @return [String] name of the gear
#   @deprecated Will be removed once typeless gears is completed
class Gear
  include Mongoid::Document
  embedded_in :application, class_name: Application.name
  field :server_identity, type: String
  field :uuid, type: String, default: ""
  field :uid, type: Integer
  field :name, type: String, default: ""
  field :quarantined, type: Boolean, default: false
  field :removed, type: Boolean
  field :host_singletons, type: Boolean, default: false
  field :app_dns, type: Boolean, default: false
  field :sparse_carts, type: Array, default: []
  field :group_instance_id, type: Moped::BSON::ObjectId
  embeds_many :port_interfaces, class_name: PortInterface.name

  # Initializes the gear
  def initialize(attrs, options = nil)
    custom_id = attrs[:custom_id]
    attrs.delete(:custom_id)
    group_instance = attrs[:group_instance]
    attrs.delete(:group_instance)

    super(attrs, options)
    self._id = custom_id unless custom_id.nil?
    self.uuid = self._id.to_s if self.uuid.blank? || self.uuid.length > 32
    if app_dns
      self.name = group_instance.application.name unless self.name.present?
    else
      self.name = self.uuid.to_s unless self.name.present?
    end
    self.group_instance_id = group_instance._id
  end

  # assume that this is run within application lock with fresh data
  def self.make_predictable_uuid(app)
    uuids = app.gears.map {|g| g.uuid }
    1.upto(Float::INFINITY) do |index| # find uuid not already used
      uuid = "#{app.domain_namespace}-#{app.canonical_name}-#{index}"
      return uuid if !uuids.include? uuid
    end
  end

  def component_instances
    gi_cis = application.component_instances.where(group_instance_id: self.group_instance_id)
    gear_cis = []
    gi_cis.each do |ci|
      if ci.is_sparse?
        gear_cis << ci if (self.host_singletons or self.sparse_carts.include? ci._id)
      else
        gear_cis << ci
      end
    end
    gear_cis
  end

  def group_instance
    application.group_instances.find(self.group_instance_id)
  end

  def self.base_filesystem_gb(gear_size)
    Rails.cache.fetch(gear_size + "_quota_blocks", :expires_in => 1.day) do
      proxy = OpenShift::ApplicationContainerProxy.find_one(gear_size)
      quota_blocks = proxy.get_quota_blocks
      # calculate the minimum storage in GB - blocks are 1KB each
      [quota_blocks / 1048576, 1].max
    end
  end

  def self.base_file_limit(gear_size)
    Rails.cache.fetch(gear_size + "_quota_files", :expires_in => 1.day) do
      proxy = OpenShift::ApplicationContainerProxy.find_one(gear_size)
      quota_files = proxy.get_quota_files
      quota_files
    end
  end

  def self.gear_sizes_display_string
    # Ex: (small(default)|medium|large)
    out = '('
    Rails.configuration.openshift[:gear_sizes].each_with_index do |gear_size, index|
      out += gear_size
      out += '(default)' if gear_size == Rails.configuration.openshift[:default_gear_size]
      out += '|' unless index == (Rails.configuration.openshift[:gear_sizes].length - 1)
    end
    out += ')'
  end

  def self.valid_gear_size?(gear_size)
    Rails.configuration.openshift[:gear_sizes].include?(gear_size)
  end

  def reserve_uid(gear_size = nil, region_id = nil)
    gear_size = group_instance.gear_size unless gear_size
    opts = { :node_profile => gear_size, :least_preferred_servers => non_ha_server_identities,
             :restricted_servers => restricted_server_identities, :existing_gears_hosting => server_identities_gears_map,
             :gear => self, :platform => group_instance.platform, :region_id => region_id}
    @container = OpenShift::ApplicationContainerProxy.find_available(opts)
    reserved_uid = @container.reserve_uid
    Application.where({"_id" => application._id, "gears.uuid" => self.uuid}).update({"$set" => {"gears.$.server_identity" => @container.id, "gears.$.uid" => reserved_uid}})
    self.server_identity = @container.id
    self.uid = reserved_uid
  end

  def unreserve_uid
    get_proxy.unreserve_uid(self.uid) if get_proxy
    Application.where({"_id" => application._id, "gears.uuid" => self.uuid}).update({"$set" => {"gears.$.server_identity" => nil, "gears.$.uid" => nil}})
    self.server_identity = nil
    self.uid = nil
  end

  def create_gear(sshkey_required=false)
    result_io = get_proxy.create(self, nil, nil, sshkey_required)
    application.process_commands(result_io, nil, self)
    result_io
  end

  def destroy_gear(keep_uid=false, is_group_rollback=false)
    result_io = get_proxy.destroy(self, keep_uid, is_group_rollback)
    application.process_commands(result_io, nil, self)
    result_io
  end

  def publish_routing_info
    self.port_interfaces.each do |pi|
      pi.publish_endpoint(self.application)
    end
  end

  def register_dns
    dns = OpenShift::DnsService.instance
    begin
      dns.register_application(self.name, application.domain_namespace, public_hostname)
      dns.publish
    ensure
      dns.close
    end
  end

  def deregister_dns
    dns = OpenShift::DnsService.instance
    begin
      dns.deregister_application(self.name, self.application.domain_namespace)
      dns.publish
    ensure
      dns.close
    end
  end

  def status(component_instance)
    get_proxy.status(self, component_instance)
  end

  def has_component?(component_instance)
    return true if self.component_instances.include? component_instance
    return false
  end

  # Installs the specified component on the gear.
  #
  # == Parameters:
  # component::
  #   {ComponentInstance} to install.
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  # Exit codes:
  #   success = 0
  # @raise [OpenShift::NodeException] on failure
  def add_component(component, init_git_url=nil)
    result_io = ResultIO.new
    unless self.removed
      result_io = get_proxy.add_component(self, component, init_git_url)
      component.process_properties(result_io)
      application.process_commands(result_io, component._id, self)
    end
    raise OpenShift::NodeException.new("Unable to add component #{component.cartridge_name}::#{component.component_name}", result_io.exitcode, result_io) if result_io.exitcode != 0
    if component.is_sparse? and !self.sparse_carts.include?(component._id)
      self.sparse_carts << component._id
      self.save!
    end
    result_io
  end

  # Performs the post-configuration steps for the specified component on the gear.
  #
  # == Parameters:
  # component::
  #   {ComponentInstance} to configure.
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  # Exit codes:
  #   success = 0
  # @raise [OpenShift::NodeException] on failure
  def post_configure_component(component, init_git_url=nil)
    result_io = get_proxy.post_configure_component(self, component, init_git_url)
    component.process_properties(result_io)
    application.update_deployments_from_result(result_io)
    application.process_commands(result_io, component._id, self)
    raise OpenShift::NodeException.new("Unable to post-configure component #{component.cartridge_name}::#{component.component_name}", result_io.exitcode, result_io) if result_io.exitcode != 0
    result_io
  end

  # Performs the deploy steps for this gear.
  #
  # == Parameters:
  # hot_deploy::
  #   Indicates whether this is a hot deploy
  # force_clean_build::
  #   Indicates whether this should be a clean build
  # ref::
  #   The ref to deploy
  # artifact_url::
  #   The url of the artifacts to deploy
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  # Exit codes:
  #   success = 0
  # @raise [OpenShift::NodeException] on failure
  def deploy(hot_deploy=false, force_clean_build=false, ref=nil, artifact_url=nil)
    result_io = get_proxy.deploy(self, hot_deploy, force_clean_build, ref, artifact_url)
    application.update_deployments_from_result(result_io)
    #application.process_commands(result_io, nil, self)
    raise OpenShift::NodeException.new("Unable to deploy #{application.name}", result_io.exitcode, result_io) if result_io.exitcode != 0
    result_io
  end

  # Performs the activate steps for this gear.
  #
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  # Exit codes:
  #   success = 0
  # @raise [OpenShift::NodeException] on failure
  def activate(deployment_id)
    result_io = get_proxy.activate(self, deployment_id)
    application.update_deployments_from_result(result_io)
    #application.process_commands(result_io, nil, self)
    raise OpenShift::NodeException.new("Unable to activate #{deployment_id} for #{application.name}", result_io.exitcode, result_io) if result_io.exitcode != 0
    result_io
  end

  # Uninstalls the specified component from the gear.
  #
  # == Parameters:
  # component::
  #   {ComponentInstance} to uninstall.
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  # Exit codes:
  #   success = 0
  # @raise [OpenShift::NodeException] on failure
  def remove_component(component)
    result_io = ResultIO.new
    unless self.removed
      result_io = get_proxy.remove_component(self, component)
      application.process_commands(result_io, component._id, self)
    end
    if component.is_sparse?
      self.sparse_carts.delete(component._id)
      self.save!
    end
    result_io
  end

  # Used for identify methods like start/stop etc. which can be handled transparently by an {OpenShift::ApplicationContainerProxy}
  # @see Object::respond_to?
  # @see http://ruby-doc.org/core-1.9.3/Object.html#method-i-respond_to-3F
  def respond_to?(sym, include_private=false)
    get_proxy.respond_to?(sym, include_private) || super
  end

  # Used for handle methods like start/stop etc. which can be handled transparently by an {OpenShift::ApplicationContainerProxy}
  # @see BasicObject::method_missing
  # @see http://www.ruby-doc.org/core-1.9.3/BasicObject.html
  def method_missing(sym, *args, &block)
    sym = :reload if sym == :reload_config
    new_args = args.dup.unshift(self)

    if get_proxy.nil? and self.server_identity.nil?
      raise OpenShift::OOException.new("The node to create the gear on has not yet been identified")
    end

    return get_proxy.send(sym, *new_args) if get_proxy.respond_to?(sym, false)
    super(sym, *args, &block)
  end

  # Gets the public hostname for the Node this gear is hosted on
  # == Returns:
  # @return [String] Public hostname of the node the gear is hosted on.
  def public_hostname
    get_proxy.get_public_hostname
  end

  # Gets the public IP address for the Node this gear is hosted on
  # == Returns:
  # @return [String] Public IP address of the node the gear is hosted on.
  def get_public_ip_address
    get_proxy.get_public_ip_address
  end

  # Gets the list of server identities where gears from this gear's group instance are hosted
  # == Returns:
  # @return [Array] List of server identities where gears from this gear's group instance are hosted.
  def non_ha_server_identities
    group_instance.server_identities.uniq
  end

  # Gets the map of server identities to the number of gears (for this particular app) hosted on them
  # == Returns:
  # @return [Array] List of server identities where gears from this gear's group instance are hosted.
  # @return Hash of server identities => number of gears for this application that are hosted on them
  def server_identities_gears_map
    si_map = {}
    group_instance.gears.each do |gear|
      if gear.server_identity.present?
        si_map[gear.server_identity] = 0 unless si_map[gear.server_identity]
        si_map[gear.server_identity] += 1
      end
    end
    si_map
  end

  # Gets the list of server identities where this gear cannot be hosted
  # == Returns:
  # @return [Array] List of server identities where this gear cannot be hosted
  def restricted_server_identities
    restricted_nodes = []
    if !Rails.configuration.openshift[:allow_multiple_haproxy_on_node] and self.application.scalable and self.component_instances.select { |ci| ci.is_web_proxy? }.present?
      self.group_instance.gears.each do |gear|
        # skip if this is the current gear itself or if its node hasn't been determined yet
        next if gear.uuid == self.uuid or gear.server_identity.nil?
        restricted_nodes << gear.server_identity if gear.component_instances.select { |ci| ci.is_web_proxy? }.present?
      end
    end
    restricted_nodes
  end

  # Given a set of gears, retrieve the state of the gear
  #
  # == Parameters:
  # gears::
  #   Array of {Gear}s to retrieve state for.
  #
  # == Returns:
  # Hash of Gear._id => state representing the state of each gear
  def self.get_gear_states(gears, timeout=nil)
    gear_states = {}
    tag = ""
    handle = RemoteJob.create_parallel_job(timeout || 10)
    RemoteJob.run_parallel_on_gears(gears, handle) { |exec_handle, gear|
      if gear.get_proxy
        RemoteJob.add_parallel_job(exec_handle, tag, gear, gear.get_proxy.get_show_state_job(gear))
      else
        gear_states[gear.uuid.to_s] = "unknown"
      end
    }
    result_io = ResultIO.new
    RemoteJob.get_parallel_run_results(handle) { |tag, gear, output, status|
      if status != 0
        Rails.logger.error("Error getting application state from gear: '#{gear}' with status: '#{status}' and output: #{output}")
        gear_states[gear] = 'unknown'
      else
        result_io.parse_output(output, gear)
        gear_states[gear] = output.split("\n").select{|i| i.start_with? 'CLIENT_RESULT'}.first.split(":")[1].strip rescue "unknown"
      end
    }
    [gear_states, result_io]
  end

  # Retrieves the instance of {OpenShift::ApplicationContainerProxy} that backs this gear
  #
  # == Returns:
  # {OpenShift::ApplicationContainerProxy}
  def get_proxy
    return nil unless server_identity
    @container = nil if @container && @container.id != server_identity
    @container ||= OpenShift::ApplicationContainerProxy.instance(server_identity)
  end

  def update_configuration(op, remote_job_handle, tag="")
    add_keys = op.add_keys_attrs
    remove_keys = op.remove_keys_attrs
    add_envs = op.add_env_vars
    remove_envs = op.remove_env_vars
    config = op.config

    RemoteJob.add_parallel_job(remote_job_handle, tag, self, get_proxy.get_add_authorized_ssh_keys_job(self, add_keys)) if add_keys.present?
    RemoteJob.add_parallel_job(remote_job_handle, tag, self, get_proxy.get_remove_authorized_ssh_keys_job(self, remove_keys))  if remove_keys.present?

    add_envs.each     {|env|      RemoteJob.add_parallel_job(remote_job_handle, tag, self, get_proxy.get_env_var_add_job(self, env["key"],env["value"]))} if add_envs.present?
    remove_envs.each  {|env|      RemoteJob.add_parallel_job(remote_job_handle, tag, self, get_proxy.get_env_var_remove_job(self, env["key"]))} if remove_envs.present?

    RemoteJob.add_parallel_job(remote_job_handle, tag, self, get_proxy.get_update_configuration_job(self, config)) unless config.nil? || config.empty?
  end

  def set_addtl_fs_gb(additional_filesystem_gb, remote_job_handle, tag = "addtl-fs-gb")
    base_filesystem_gb = Gear.base_filesystem_gb(self.group_instance.gear_size)
    base_file_limit = Gear.base_file_limit(self.group_instance.gear_size)
    total_fs_gb = additional_filesystem_gb + base_filesystem_gb
    total_file_limit = (total_fs_gb * base_file_limit) / base_filesystem_gb
    RemoteJob.add_parallel_job(remote_job_handle, tag, self, get_proxy.get_update_gear_quota_job(self, total_fs_gb, total_file_limit.to_i))
  end
end
