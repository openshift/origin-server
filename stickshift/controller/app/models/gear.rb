# Represents a gear created on an OpenShift Origin Node.
# @!attribute [r] group_instance
#   @return [GroupInstance] The {GroupInstance} that this gear is part of.
# @!attribute [r] server_identity
#   @return [String] DNS name of the node the gear is hosted on.
# @!attribute [r] uid
#   @return [Integer] UID of the user on the node.
# @!attribute [r] name
#   @return [String] name of the gear
#   @deprecated Will be removed once typeless gears is completed
class Gear
  include Mongoid::Document
  embedded_in :group_instance, class_name: GroupInstance.name
  field :server_identity, type: String
  field :uid, type: Integer
  field :name, type: String

  # Initializes the gear
  def initialize(attrs = nil, options = nil)
    super
    
    #@todo: Remove when typeless gears is completed
    name = self._id.to_s[0..9]
  end
  
  # Finds a Node and creates a Gear on it. If creation fails, it attempts to delete the partially created gear.
  #
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  # Exit codes:
  #   success = 0
  #   failure = 5
  # @raise [StickShift::NodeException] on failure
  def create
    result_io = nil
    
    dns = StickShift::DnsService.instance
    begin
      @container = StickShift::ApplicationContainerProxy.find_available #(group_instance.gear_profile)
      self.set :server_identity, @container.id
      self.set :uid, @container.reserve_uid
      dns.register_application(self.name, self.group_instance.application.domain.namespace, public_hostname)
      dns.publish      
      result_io = @container.create(app,self)
    rescue Exception => e
      begin
        dns.deregister_application(self.name, self.group_instance.application.domain.namespace)
        dns.publish
      rescue Exception => e
        Rails.logger.debug e.inspect
        #ignore
      end
      Rails.logger.debug e.message
      Rails.logger.debug e.backtrace.join("\n")
      result_io = ResultIO.new
      result_io.errorIO << e.message
      result_io.exitcode = 5
    ensure
      dns.close
    end

    ## recovery action if creation failed above
    if result_io.exitcode != 0
      begin
        get_proxy.destroy(self.app, self)
      rescue Exception => e
        Rails.logger.debug e.message
        Rails.logger.debug e.backtrace.join("\n")
      end
      raise StickShift::NodeException.new("Unable to create gear on node", 1, result_io)
    end
    return result_io
  end
  
  # Destorys the Gear on the Node that is running it.
  #
  # == Returns:
  # A {ResultIO} object with with output or error messages from the Node.
  # Exit codes:
  #   success = 0
  # @raise [StickShift::NodeException] on failure
  def destroy
    dns = StickShift::DnsService.instance
    begin
      begin
        dns.deregister_application(self.name, self.group_instance.application.domain.namespace)
        dns.publish
      rescue Exception => e
        Rails.logger.debug e
      end

      result_io = get_proxy.destroy(app,self)
      app.process_commands(result_io)
      raise StickShift::NodeException.new("Unable to destroy gear on node", result_io.exitcode, result_io) if result_io.exitcode != 0
      return result_io
    ensure
      dns.close
    end
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
  # @raise [StickShift::NodeException] on failure
  def add_component(component)
    result_io = get_proxy.configure_cartridge(app, self, component.cartridge_name)
    component.process_properties(result_io)
    app.process_commands(result_io)
    raise StickShift::NodeException.new("Unable to add component #{component.cartridge_name}::#{component.component_name}", result_io.exitcode, result_io) if result_io.exitcode != 0
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
  # @raise [StickShift::NodeException] on failure
  def remove_component(component)
    result_io = get_proxy.deconfigure_cartridge(app, self, component.cartridge_name)
    app.process_commands(result_io)
    result_io
  end
  
  # Used for identify methods like start/stop etc. which can be handled transparently by an {StickShift::ApplicationContainerProxy}
  # @see Object::respond_to?
  # @see http://ruby-doc.org/core-1.9.3/Object.html#method-i-respond_to-3F
  def respond_to?(sym, include_private=false)
    get_proxy.respond_to?(sym, include_private) || super
  end
  
  # Used for handle methods like start/stop etc. which can be handled transparently by an {StickShift::ApplicationContainerProxy}
  # @see BasicObject::method_missing
  # @see http://www.ruby-doc.org/core-1.9.3/BasicObject.html
  def method_missing(sym, *args, &block)
    new_args = args.dup.unshift(app,self)
    return get_proxy.send(sym, *new_args) if get_proxy.respond_to?(sym,false)
    super(sym, *args, &block)
  end
  
  # Gets the public hostname for the Node this gear is hosted on
  # == Returns:
  # @return [String] Public hostname of the node the gear is hosted on.
  def public_hostname
    get_proxy.get_public_hostname
  end
  
  # Given a set of gears, retrueve the state of the gear
  #
  # == Parameters:
  # gears::
  #   Array of {Gear}s to retrieve state for.
  #
  # == Returns:
  # Hash of Gear._id => state representing the state of each gear
  def self.get_gear_states(gears)
    gear_states = {}
    tag = ""
    handle = RemoteJob.create_parallel_job
    RemoteJob.run_parallel_on_gears(gears, handle) { |exec_handle, gear|
      RemoteJob.add_parallel_job(exec_handle, tag, gear, gear.get_proxy.get_show_state_job(gear.app, gear))
    }
    RemoteJob.get_parallel_run_results(handle) { |tag, gear, output, status|
      if status != 0
        Rails.logger.error("Error getting application state from gear: '#{gear}' with status: '#{status}' and output: #{output}", 143)
        gear_states[gear] = 'unknown'
      else
        gear_states[gear] = output
      end
    }
    gear_states
  end

  # Retrieves the instance of {StickShift::ApplicationContainerProxy} that backs this gear
  #
  # == Returns:
  # {StickShift::ApplicationContainerProxy}
  def get_proxy
    if @container.nil? and !self.server_identity.nil?
      @container = StickShift::ApplicationContainerProxy.instance(self.server_identity)
    end    
    return @container
  end
  
  # Convinience method to get the {Application}
  def app
    @app ||= group_instance.application
  end
end
