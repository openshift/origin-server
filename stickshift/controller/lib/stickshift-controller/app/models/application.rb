require 'state_machine'

class Application < StickShift::Cartridge
  attr_accessor :user, :creation_time, :uuid, :aliases, :cart_data, 
                :state, :group_instance_map, :comp_instance_map, :conn_endpoints_list,
                :domain, :group_override_map, :working_comp_inst_hash,
                :working_group_inst_hash, :configure_order, :start_order,
                :scalable, :proxy_cartridge, :init_git_url, :node_profile, :ngears
  primary_key :name
  exclude_attributes :user, :comp_instance_map, :group_instance_map, 
                :working_comp_inst_hash, :working_group_inst_hash,
                :init_git_url, :group_override_map
  include_attributes :comp_instances, :group_instances

  APP_NAME_MAX_LENGTH = 32
  NAMESPACE_MAX_LENGTH = 16
  UNSCALABLE_FRAMEWORKS = ["jenkins-1.4", "diy-0.1"]
  SCALABLE_EMBEDDED_CARTS = ["mysql-5.1", "jenkins-client-1.4"]
  
  validate :extended_validator
  
  validates_each :name, :allow_nil =>false do |record, attribute, val|
    if !(val =~ /\A[A-Za-z0-9]+\z/)
      record.errors.add attribute, {:message => "Invalid #{attribute} specified: #{val}", :exit_code => 105}
    end
    if val and val.length > APP_NAME_MAX_LENGTH
      record.errors.add attribute, {:message => "The supplied application name '#{val}' is too long. (Max permitted length: #{APP_NAME_MAX_LENGTH} characters)", :exit_code => 105}
    end
    Rails.logger.debug "Checking to see if application name is black listed"    
    if StickShift::ApplicationContainerProxy.blacklisted?(val)
      record.errors.add attribute, {:message => "The supplied application name '#{val}' is not allowed", :exit_code => 105}
    end
  end
  
  validates_each :node_profile, :allow_nil =>true do |record, attribute, val|
    if !(val =~ /\A(jumbo|exlarge|large|micro|medium|small)\z/)
      record.errors.add attribute, {:message => "Invalid Profile: #{val}.  Must be: (jumbo|exlarge|large|medium|micro|small)", :exit_code => 134}
    end
  end

  def extended_validator
    notify_observers(:validate_application)
  end

  # @param [CloudUser] user
  # @param [String] app_name Application name
  # @param [optional, String] uuid Unique identifier for the application
  # @param [deprecated, String] node_profile Node profile for the first application gear
  # @param [deprecated, String] framework Cartridge name to use as the framwwork of the application
  def initialize(user=nil, app_name=nil, uuid=nil, node_profile=nil, framework=nil, template=nil, will_scale=false, domain=nil)
    self.user = user
    self.domain = domain
    self.node_profile = node_profile
    self.creation_time = DateTime::now().strftime
    self.uuid = uuid || StickShift::Model.gen_uuid
    self.scalable = will_scale
    self.ngears = 0
    
    if template.nil?
      if self.scalable
        descriptor_hash = YAML.load(template_scalable_app(app_name, framework))
        from_descriptor(descriptor_hash)
        self.proxy_cartridge = "haproxy-1.4"
      else
        from_descriptor({"Name"=>app_name, "Subscribes"=>{"doc-root"=>{"Type"=>"FILESYSTEM:doc-root"}}})
        self.requires_feature = []
        self.requires_feature << framework unless framework.nil?      
      end
    else
      template_descriptor = YAML.load(template.descriptor_yaml)
      template_descriptor["Name"] = app_name
      from_descriptor(template_descriptor)
      @init_git_url = template.git_url
    end
  end

  def add_to_requires_feature(feature)
    prof = @profile_name_map[@default_profile]
    if self.scalable
      # add to the proxy component
      comp_name = "proxy" if comp_name.nil?
      prof = @profile_name_map[@default_profile]
      cinst = ComponentInstance::find_component_in_cart(prof, self, comp_name, self.get_name_prefix)
      raise StickShift::NodeException.new("Cannot find component '#{comp_name}' in app #{self.name}.", "-101", result_io) if cinst.nil?
      comp,profile,cart = cinst.get_component_definition(self)
      raise StickShift::UserException.new("#{feature} already embedded in '#{@name}'", 101) if comp.depends.include? feature
      fcart = self.framework
      conn = StickShift::Connection.new("#{feature}-web-#{fcart}")
      conn.components = ["proxy/#{feature}", "web/#{fcart}"]
      prof.add_connection(conn)
      conn = StickShift::Connection.new("#{feature}-proxy-#{fcart}")
      conn.components = ["proxy/#{feature}", "proxy/#{fcart}"]
      prof.add_connection(conn)

      #  FIXME: Booya - hacks galore -- fix this to be more generic when
      #         scalable apps allow more components in SCALABLE_EMBEDDED_CARTS
      if feature == "jenkins-client-1.4"
        conn = StickShift::Connection.new("#{feature}-proxy-haproxy-1.4")
        conn.components = ["proxy/#{feature}", "proxy/haproxy-1.4"]
        prof.add_connection(conn)
      end

      comp.depends << feature
    else
      self.requires_feature.each { |cart|
        conn = StickShift::Connection.new("#{feature}-#{cart}")
        conn.components = [cart, feature]
        prof.add_connection(conn)
      }
      self.requires_feature << feature
    end
  end
  
  def template_scalable_app(app_name, framework)
    return "
Name: #{app_name}
Components:
  proxy:
    Dependencies: [#{framework}, \"haproxy-1.4\"]
    Subscribes:
      doc-root:
        Type: \"FILESYSTEM:doc-root\"
  web:
    Dependencies: [#{framework}]
    Subscribes:
      doc-root:
        Type: \"FILESYSTEM:doc-root\"
Groups:
  proxy:
    Components:
      proxy: proxy
  web:
    Components:
      web: web
Connections:
  auto-scale:
    Components: [\"proxy/haproxy-1.4\", \"web/#{framework}\"]
Configure-Order: [\"proxy/#{framework}\", \"proxy/haproxy-1.4\"]
"
  end

  def remove_from_requires_feature(feature)
    prof = @profile_name_map[@default_profile]
    if prof.connection_name_map
      prof.connection_name_map.delete_if {|k,v| v.components[0].include? feature or v.components[1].include? feature }
    end
    if self.scalable
      comp_name = "proxy" if comp_name.nil?
      prof = @profile_name_map[@default_profile]
      cinst = ComponentInstance::find_component_in_cart(prof, self, comp_name, self.get_name_prefix)
      raise StickShift::NodeException.new("Cannot find component '#{comp_name}' in app #{self.name}.", "-101", result_io) if cinst.nil?
      comp,profile,cart = cinst.get_component_definition(self)
      raise StickShift::UserException.new("#{feature} not embedded in '#{@name}', try adding it first", 101) if not comp.depends.include? feature
      comp.depends.delete(feature)
    else
      self.requires_feature.delete feature
    end
  end

  # Find an application to which user has access
  # @param [CloudUser] user
  # @param [String] app_name
  # @return [Application]
  def self.find(user, app_name)
    app = nil
    if user.applications
      user.applications.each do |next_app|
        if next_app.name == app_name
          app = next_app
          break
        end
      end
    else
      app = super(user.login, app_name)
      return nil unless app
      app.user = user
      app.reset_state
    end
    app
  end
  
  # Find an applications to which user has access
  # @param [CloudUser] user
  # @return [Array<Application>]
  def self.find_all(user)
    apps = nil
    if user.applications
      apps = user.applications
    else
      apps = super(user.login)
      apps.each do |app|
        app.user = user
        app.reset_state
      end
      user.applications = apps
    end
    apps
  end
  
  def self.find_by_uuid(uuid)
    hash = StickShift::DataStore.instance.find_by_uuid(self.name,uuid)
    return nil unless hash
    user = CloudUser.hash_to_obj hash
    app  = nil
    user.applications.each do |next_app|
      if next_app.uuid == uuid
        app = next_app
        break
      end
    end
    return app
  end
  
  def self.hash_to_obj(hash)
    domain = nil
    if hash["domain"]
      domain = Domain.hash_to_obj(hash["domain"])
    end
    app = super(hash)
    app.domain = domain
    app
  end
  
  # @overload Application.get_available_cartridges(cart_type)
  #   @deprecated
  #   Returns List of names of available cartridges of specified type
  #   @param [String] cart_type Must be "standalone" or "embedded" or nil
  #   @return [Array<String>] 
  # @overload Application.get_available_cartridges
  #   @return [Array<String>]   
  #   Returns List of names of all available cartridges
  def self.get_available_cartridges(cart_type=nil)
    cart_names = CartridgeCache.cartridge_names(cart_type)
  end
  
  # Saves the application object in the datastore
  def save
    super(user.login)
    self.ngears = 0
  end
  
  # Deletes the application object from the datastore
  def delete
    super(user.login)
  end
  
  # Processes the application descriptor and creates all the gears necessary to host the application.
  # Destroys application on all gears if any gear fails
  # @return [ResultIO]
  def create
    result_io = ResultIO.new
    self.class.notify_observers(:before_application_create, {:application => self, :reply => result_io})
    gears_created = []
    begin
      elaborate_descriptor()
      if self.scalable
        raise StickShift::UserException.new("Scalable app cannot be of type #{UNSCALABLE_FRAMEWORKS.join(' ')}", "108", result_io) if UNSCALABLE_FRAMEWORKS.include? framework
      end
      user.applications << self
      Rails.logger.debug "Creating gears"
      group_instances.uniq.each do |ginst|
        create_result, new_gear = ginst.add_gear(self)
        result_io.append create_result
      end

      self.gear.name = self.name unless scalable
      self.class.notify_observers(:application_creation_success, {:application => self, :reply => result_io})              
    rescue Exception => e
      Rails.logger.debug e.message
      Rails.logger.debug e.backtrace.join("\n")
      Rails.logger.debug "Rolling back application gear creation"
      result_io.append self.destroy
      self.class.notify_observers(:application_creation_failure, {:application => self, :reply => result_io})
      raise
    ensure
      save
    end
    self.class.notify_observers(:after_application_create, {:application => self, :reply => result_io})
    result_io
  end
  
  #convinence method to cleanup an application
  def cleanup_and_delete
    reply = ResultIO.new
    reply.append self.destroy_dns
    reply.append self.deconfigure_dependencies
    reply.append self.destroy
    self.delete
    reply
  end
  
  # Destroys all gears. Logs message but does not throw an exception on failure to delete any particular gear.
  def destroy
    reply = ResultIO.new
    self.class.notify_observers(:before_application_destroy, {:application => self, :reply => reply})
    s,f = run_on_gears(nil, reply, false) do |gear, r|
      r.append gear.destroy
      group_instance = self.group_instance_map[gear.group_instance_name]
      group_instance.gears.delete(gear)
    end
    self.save if self.persisted?
          
    f.each do |data|
      Rails.logger.debug("Unable to clean up application on gear #{data[:gear]} due to exception #{data[:exception].message}")
      Rails.logger.debug(data[:exception].backtrace.inspect)
    end
    self.class.notify_observers(:after_application_destroy, {:application => self, :reply => reply})    
    reply
  end

  def web_cart
    return framework 
  end
  
  def gears
    self.group_instances.uniq.map{ |ginst| ginst.gears }.flatten
  end

  def scaleup(comp_name=nil)
    result_io = ResultIO.new
    if not self.scalable
      raise StickShift::NodeException.new("Cannot scale a non-scalable application", "-100", result_io)
    end
    comp_name = "web" if comp_name.nil?
    prof = @profile_name_map[@default_profile]
    cinst = ComponentInstance::find_component_in_cart(prof, self, comp_name, self.get_name_prefix)
    raise StickShift::NodeException.new("Cannot find #{comp_name} in app #{self.name}.", "-101", result_io) if cinst.nil?
    ginst = self.group_instance_map[cinst.group_instance_name]
    raise StickShift::NodeException.new("Cannot find group #{cinst.group_instance_name} for #{comp_name} in app #{self.name}.", "-101", result_io) if ginst.nil?
    result, new_gear = ginst.add_gear(self)
    result_io.append result
    result_io.append self.configure_dependencies
    self.execute_connections
    result_io
  end

  def scaledown(comp_name=nil)
    result_io = ResultIO.new
    if not self.scalable
      raise StickShift::NodeException.new("Cannot scale a non-scalable application", "-100", result_io)
    end
    comp_name = "web" if comp_name.nil?
    prof = @profile_name_map[@default_profile]
    cinst = ComponentInstance::find_component_in_cart(prof, self, comp_name, self.get_name_prefix)
    raise StickShift::NodeException.new("Cannot find #{comp_name} in app #{self.name}.", "-101", result_io) if cinst.nil?
    ginst = self.group_instance_map[cinst.group_instance_name]
    raise StickShift::NodeException.new("Cannot find group #{cinst.group_instance_name} for #{comp_name} in app #{self.name}.", "-101", result_io) if ginst.nil?
    # remove any gear out of this ginst
    raise StickShift::NodeException.new("Cannot scale below one gear", "-100", result_io) if ginst.gears.length == 1

    gear = ginst.gears.first

    dns = StickShift::DnsService.instance
    begin
      dns.deregister_application(gear.name, @domain.namespace)
      dns.publish
    ensure
      dns.close
    end

    comps_to_deconfigure = gear.configured_components.dup
    comps_to_deconfigure.each { |conf_comp|
      cinst = self.comp_instance_map[conf_comp]
      result_io.append gear.deconfigure(cinst)
    }

    result_io.append gear.destroy
    ginst.gears.delete gear

    # inform anyone who needs to know that this gear is no more
    self.configure_dependencies
    self.execute_connections
    result_io
  end
  
  # Elaborates the descriptor, deconfigures cartridges that were removed and configures cartridges that were added to the application dependencies.
  # If a node is empty after removing components, then the gear is destroyed. Errors that occur while removing cartridges are logged but no exception is thrown.
  # If an error occurs while configuring a cartridge, then the cartirdge is deconfigures on all nodes and an exception is thrown.
  def configure_dependencies
    reply = ResultIO.new
    self.class.notify_observers(:before_application_configure, {:application => self, :reply => reply})
    
    removed_component_instances = elaborate_descriptor()
    #remove unused components
    removed_component_instances.each do |comp_inst_name|
      comp_inst = self.comp_instance_map[comp_inst_name]
      next if comp_inst.parent_cart_name == self.name
      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.deconfigure(comp_inst)
        r.append process_cartridge_commands(r.cart_commands)
        # self.save
      end
      
      f.each do |failed_data|
        Rails.logger.debug("Failed to deconfigure cartridge #{comp_inst.parent_cart_name} on gear #{failed_data[:gear].server_identity}:#{failed_data[:gear].uuid}")
        Rails.logger.debug("Exception #{failed_data[:exception].message}")
        Rails.logger.debug("#{failed_data[:exception].backtrace.inspect}")
      end
      
      run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.destroy if gear.configured_components.length == 0
        # self.save        
      end
      group_inst.gears.delete_if { |gear| gear.configured_components.length == 0 }
    end
    cleanup_deleted_components
    # self.save
    
    exceptions = []
    Rails.logger.debug "Configure order is #{self.configure_order.inspect}"
    #process new additions
    #TODO: fix configure after framework cartridge is no longer a requirement for adding embedded cartridges
    self.configure_order.each do |comp_inst_name|
      comp_inst = self.comp_instance_map[comp_inst_name]
      next if comp_inst.parent_cart_name == self.name
      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      begin
        group_inst.fulfil_requirements(self)
        run_on_gears(group_inst.gears, reply) do |gear, r|
          doExpose = false
          if self.scalable and comp_inst.parent_cart_name!=self.proxy_cartridge
            doExpose = true if not gear.configured_components.include? comp_inst.name
          end
          r.append gear.configure(comp_inst, @init_git_url)
          begin
            r.append gear.expose_port(comp_inst) if doExpose
          rescue Exception=>e
          end
          r.append process_cartridge_commands(r.cart_commands)
        end
      rescue Exception => e
        Rails.logger.debug e.message
        Rails.logger.debug e.backtrace.inspect        
        
        successful_gears = []
        successful_gears = e.message[:successful].map{|g| g[:gear]} if e.message[:successful]
        failed_gears = []
        failed_gears = e.message[:failed].map{|g| g[:gear]} if e.message[:failed]
        gear_exception = e.message[:exception]        

        #remove failed component from all gears
        run_on_gears(successful_gears, reply, false) do |gear, r|
          r.append gear.deconfigure(comp_inst)
          r.append process_cartridge_commands(r.cart_commands)
        end
        run_on_gears(failed_gears, reply, false) do |gear, r|
          r.append gear.deconfigure(comp_inst, true)
          r.append process_cartridge_commands(r.cart_commands)
        end
        
        #destroy any unused gears
        run_on_gears(group_inst.gears, reply, false) do |gear, r|
          r.append gear.destroy if gear.configured_components.length == 0
        end
        group_inst.gears.delete_if { |gear| gear.configured_components.length == 0 }

        self.save
        exceptions << gear_exception
      end
    end
    
    unless exceptions.empty?
      raise exceptions.first
    end
    
    self.save
    self.class.notify_observers(:after_application_configure, {:application => self, :reply => reply})
    reply
  end

  def execute_connections_optimized
    return if not self.scalable

    self.conn_endpoints_list.each { |conn|
      pub_inst = self.comp_instance_map[conn.from_comp_inst]
      pub_ginst = self.group_instance_map[pub_inst.group_instance_name]

      tag = ""
      handle = RemoteJob.create_parallel_job
      RemoteJob.run_parallel_on_gears(pub_ginst.gears, handle) { |exec_handle, gear|
        appname = gear.name
        connector_name = conn.from_connector.name
        cart = pub_inst.parent_cart_name
        input_args = [appname, self.domain.namespace, gear.uuid]
        
        job = gear.get_execute_connector_job(cart, connector_name, input_args)
        RemoteJob.add_parallel_job(exec_handle, tag, gear, job)
      }
      pub_out = []
      RemoteJob.get_parallel_run_results(handle) { |tag, gear, output, status|
        if status==0
          pub_out.push("'#{gear}'='#{output}'")
        end
      }
      input_to_subscriber = Shellwords::shellescape(pub_out.join(' '))
      Rails.logger.debug "Output of publisher - '#{pub_out}'"

      sub_inst = self.comp_instance_map[conn.to_comp_inst]
      sub_ginst = self.group_instance_map[sub_inst.group_instance_name]
      handle = RemoteJob.create_parallel_job
      RemoteJob.run_parallel_on_gears(sub_ginst.gears, handle) { |exec_handle, gear|
        appname = gear.name
        connector_name = conn.to_connector.name
        cart = sub_inst.parent_cart_name
        input_args = [appname, self.domain.namespace, gear.uuid, input_to_subscriber]
        
        job = gear.get_execute_connector_job(cart, connector_name, input_args)
        RemoteJob.add_parallel_job(exec_handle, tag, gear, job)
      }
      # we dont care about subscriber's output/status
    }
  end

  # execute all connections
  def execute_connections
    return execute_connections_optimized 
    return if not self.scalable
    self.conn_endpoints_list.each { |conn|
      # get publisher's gears, execute the connector, and
      # give the output to subscriber gears
      pub_inst = self.comp_instance_map[conn.from_comp_inst]
      pub_ginst = self.group_instance_map[pub_inst.group_instance_name]

      r = ResultIO.new
      pub_out = []
      run_on_gears(pub_ginst.gears, r, false) do |gear, r|
        appname = gear.name

        gout, gstatus = gear.execute_connector(pub_inst, conn.from_connector.name, [appname, self.domain.namespace, gear.uuid])

        if gstatus==0
          pub_out.push("'#{gear.uuid}'='#{gout}'")
        end
      end
      input_to_subscriber = Shellwords::shellescape(pub_out.join(' '))
      Rails.logger.debug "Output of publisher - '#{pub_out}'"

      sub_inst = self.comp_instance_map[conn.to_comp_inst]
      sub_ginst = self.group_instance_map[sub_inst.group_instance_name]

      run_on_gears(sub_ginst.gears, r, false) do |gear, r|
        appname = gear.name
        gout, gstatus = gear.execute_connector(sub_inst, conn.to_connector.name, [appname, self.domain.namespace, gear.uuid, input_to_subscriber])
      end
    }
  end
  
  # Deconfigure all cartriges for the application. Errors are logged but no exception is thrown.
  def deconfigure_dependencies
    reply = ResultIO.new
    self.class.notify_observers(:before_application_deconfigure, {:application => self, :reply => reply})  
    if(self.configure_order)
      self.configure_order.reverse.each do |comp_inst_name|
        comp_inst = self.comp_instance_map[comp_inst_name]
        next if comp_inst.parent_cart_name == self.name
        group_inst = self.group_instance_map[comp_inst.group_instance_name]
        begin
          run_on_gears(group_inst.gears, reply, false) do |gear, r|
            r.append gear.deconfigure(comp_inst)
            r.append process_cartridge_commands(r.cart_commands)
          end
        rescue  Exception => e
          # raise e
        end
      end
    end
    self.save if self.persisted?
    self.class.notify_observers(:after_application_deconfigure, {:application => self, :reply => reply})
    reply
  end
  
  # Start a particular dependency on all gears that host it. 
  # If unable to start a component, the application is stopped on all gears
  # @param [String] dependency Name of a cartridge to start. Set to nil for all dependencies.
  # @param [Boolean] force_stop_on_failure
  def start(dependency=nil, stop_on_failure=true)
    reply = ResultIO.new
    self.class.notify_observers(:before_start, {:application => self, :reply => reply, :dependency => dependency})
    self.start_order.each do |comp_inst_name|
      comp_inst = self.comp_instance_map[comp_inst_name]
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      next if comp_inst.parent_cart_name == self.name
      
      begin
        group_inst = self.group_instance_map[comp_inst.group_instance_name]
        run_on_gears(group_inst.gears, reply) do |gear, r|
          r.append gear.start(comp_inst)
        end
      rescue Exception => e
        gear_exception = e.message[:exception]
        self.stop(dependency,false,false) if stop_on_failure
        raise gear_exception
      end
    end
    self.class.notify_observers(:after_start, {:application => self, :reply => reply, :dependency => dependency})
    reply
  end
  
  # Stop a particular dependency on all gears that host it.
  # @param [String] dependency Name of a cartridge to start. Set to nil for all dependencies.
  # @param [Boolean] force_stop_on_failure
  # @param [Boolean] throw_exception_on_failure
  def stop(dependency=nil,force_stop_on_failure=true, throw_exception_on_failure=true)
    reply = ResultIO.new
    self.class.notify_observers(:before_stop, {:application => self, :reply => reply, :dependency => dependency})
    self.start_order.reverse.each do |comp_inst_name|
      comp_inst = self.comp_instance_map[comp_inst_name]
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      next if comp_inst.parent_cart_name == self.name
      
      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.stop(comp_inst)
      end
      
      if(f.length > 0)
        self.force_stop(dependency,false) if(force_stop_on_failure)
        raise f[0][:exception] if(throw_exception_on_failure)
      end
    end
    self.class.notify_observers(:after_stop, {:application => self, :reply => reply, :dependency => dependency})
    reply    
  end
  
  # Force stop a particular dependency on all gears that host it.
  # @param [String] dependency Name of a cartridge to stop. Set to nil for all dependencies.
  # @param [Boolean] throw_exception_on_failure
  def force_stop(dependency=nil, throw_exception_on_failure=true)
    reply = ResultIO.new
    self.class.notify_observers(:before_force_stop, {:application => self, :reply => reply, :dependency => dependency})
    self.start_order.each do |comp_inst_name|
      comp_inst = self.comp_instance_map[comp_inst_name]
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      
      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.force_stop(comp_inst)
      end
      
      raise f[0][:exception] if(f.length > 0 and throw_exception_on_failure)
    end
    self.class.notify_observers(:after_force_stop, {:application => self, :reply => reply, :dependency => dependency})
    reply    
  end
  
  # Restart a particular dependency on all gears that host it.
  # @param [String] dependency Name of a cartridge to restart. Set to nil for all dependencies.
  def restart(dependency=nil)
    reply = ResultIO.new
    self.class.notify_observers(:before_restart, {:application => self, :reply => reply, :dependency => dependency})
    self.start_order.each do |comp_inst_name|
      comp_inst = self.comp_instance_map[comp_inst_name]
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      
      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.restart(comp_inst)
      end
      
      raise f[0][:exception] if(f.length > 0)
    end
    self.class.notify_observers(:after_restart, {:application => self, :reply => reply, :dependency => dependency})
    reply    
  end
  
  # Reload a particular dependency on all gears that host it.
  # @param [String] dependency Name of a cartridge to reload. Set to nil for all dependencies.
  def reload(dependency=nil)
    reply = ResultIO.new
    self.class.notify_observers(:before_reload, {:application => self, :reply => reply, :dependency => dependency})
    self.start_order.each do |comp_inst_name|
      comp_inst = self.comp_instance_map[comp_inst_name]
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      
      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.reload(comp_inst)
      end
      
      raise f[0][:exception] if(f.length > 0)
    end
    self.class.notify_observers(:after_reload, {:application => self, :reply => reply, :dependency => dependency})
    reply
  end
  
  # Retrieves status for a particular dependency on all gears that host it.
  # @param [String] dependency Name of a cartridge
  def status(dependency=nil)
    reply = ResultIO.new
    self.comp_instance_map.each do |comp_inst_name, comp_inst|
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      
      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.status(comp_inst)
      end
      
      raise f[0][:exception] if(f.length > 0)      
    end
    reply
  end
  
  # Invokes tidy for a particular dependency on all gears that host it.
  # @param [String] dependency Name of a cartridge
  def tidy(dependency=nil)
    reply = ResultIO.new
    self.comp_instance_map.each do |comp_inst_name, comp_inst|
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      
      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.tidy(comp_inst)
      end
      
      raise f[0][:exception] if(f.length > 0)      
    end
    reply
  end
  
  # Invokes threaddump for a particular dependency on all gears that host it.
  # @param [String] dependency Name of a cartridge
  def threaddump(dependency=nil)
    reply = ResultIO.new
    self.comp_instance_map.each do |comp_inst_name, comp_inst|
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      
      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.threaddump(comp_inst)
      end
      
      raise f[0][:exception] if(f.length > 0)      
    end
    reply
  end
  
  # Invokes system_messages for a particular dependency on all gears that host it.
  # @param [String] dependency Name of a cartridge  
  def system_messages(dependency=nil)
    reply = ResultIO.new
    self.comp_instance_map.each do |comp_inst_name, comp_inst|
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      
      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.system_messages(comp_inst)
      end
      
      raise f[0][:exception] if(f.length > 0)      
    end
    reply
  end

  # Invokes expose_port for a particular dependency on all gears that host it.
  # @param [String] dependency Name of a cartridge
  def expose_port(dependency=nil)
    reply = ResultIO.new
    self.comp_instance_map.each do |comp_inst_name, comp_inst|
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      next if comp_inst.name == "@@app"

      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.expose_port(comp_inst)
      end

      raise f[0][:exception] if(f.length > 0)
    end
    reply
  end

  def conceal_port(dependency=nil)
    reply = ResultIO.new
    self.comp_instance_map.each do |comp_inst_name, comp_inst|
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      next if comp_inst.name == "@@app"

      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.conceal_port(comp_inst)
      end
      raise f[0][:exception] if(f.length > 0)      
    end
    reply
  end
  
  def show_port(dependency=nil)
    reply = ResultIO.new
    self.comp_instance_map.each do |comp_inst_name, comp_inst|
      next if !dependency.nil? and (comp_inst.parent_cart_name != dependency)
      next if comp_inst.name == "@@app"

      Rails.logger.debug( comp_inst.inspect )
      Rails.logger.debug( "\n" )

      group_inst = self.group_instance_map[comp_inst.group_instance_name]
      s,f = run_on_gears(group_inst.gears, reply, false) do |gear, r|
        r.append gear.show_port(comp_inst)
      end
      raise f[0][:exception] if(f.length > 0)      
    end
    reply
  end
  
  def add_authorized_ssh_key(ssh_key, key_type=nil, comment=nil)
    reply = ResultIO.new
    s,f = run_on_gears(nil,reply,false) do |gear,r|
      r.append gear.add_authorized_ssh_key(ssh_key, key_type, comment)
    end
    raise f[0][:exception] if(f.length > 0)    
    reply
  end
  
  def remove_authorized_ssh_key(ssh_key, comment=nil)
    reply = ResultIO.new
    s,f = run_on_gears(nil,reply,false) do |gear,r|
      r.append gear.remove_authorized_ssh_key(ssh_key, comment)
    end
    raise f[0][:exception] if(f.length > 0)    
    reply
  end
  
  def add_env_var(key, value)
    reply = ResultIO.new
    s,f = run_on_gears(nil,reply,false) do |gear,r|
      r.append gear.add_env_var(key, value)
    end
    raise f[0][:exception] if(f.length > 0)  
    reply
  end
  
  def remove_env_var(key)
    reply = ResultIO.new
    s,f = run_on_gears(nil,reply,false) do |gear,r|
      r.append gear.remove_env_var(key)
    end
    raise f[0][:exception] if(f.length > 0)    
    reply
  end
  
  def add_broker_key
    iv, token = StickShift::AuthService.instance.generate_broker_key(self)
    iv = Base64::encode64(iv)
    token = Base64::encode64(token)
    
    reply = ResultIO.new
    s,f = run_on_gears(nil,reply,false) do |gear,r|
      r.append gear.add_broker_auth_key(iv,token)
    end
    raise f[0][:exception] if(f.length > 0)    
    reply
  end
  
  def remove_broker_key
    reply = ResultIO.new
    s,f = run_on_gears(nil,reply,false) do |gear,r|
      r.append gear.remove_broker_auth_key
    end
    raise f[0][:exception] if(f.length > 0)    
    reply
  end
  
  def add_node_settings(gears=nil)
    reply = ResultIO.new
    
    gears = self.gears unless gears
    
    if @user.env_vars || @user.ssh_keys || @user.system_ssh_keys
      tag = ""
      handle = RemoteJob.create_parallel_job
      RemoteJob.run_parallel_on_gears(gears, handle) { |exec_handle, gear|
        @user.env_vars.each do |key, value|
          job = gear.env_var_job_add(key, value)
          RemoteJob.add_parallel_job(exec_handle, tag, gear, job)
        end if @user.env_vars
        @user.ssh_keys.each do |key_name, key_info|
          job = gear.ssh_key_job_add(key_info["key"], key_info["type"], key_name)
          RemoteJob.add_parallel_job(exec_handle, tag, gear, job)
        end if @user.ssh_keys
        @user.system_ssh_keys.each do |key_name, key_info|
          job = gear.ssh_key_job_add(key_info, nil, key_name)
          RemoteJob.add_parallel_job(exec_handle, tag, gear, job)
        end if @user.system_ssh_keys
      }
      RemoteJob.get_parallel_run_results(handle) { |tag, gear, output, status|
        if status != 0
          raise StickShift::NodeException.new("Error applying settings to gear: #{gear} with status: #{status} and output: #{output}", 143)
        end
      }
    end
    reply
  end

  def add_dns(appname, namespace, public_hostname)
    dns = StickShift::DnsService.instance
    begin
      dns.register_application(appname, namespace, public_hostname)
      dns.publish
    ensure
      dns.close
    end
  end
  
  def create_dns
    reply = ResultIO.new
    self.class.notify_observers(:before_create_dns, {:application => self, :reply => reply})    
    public_hostname = self.container.get_public_hostname

    add_dns(@name, @domain.namespace, public_hostname)

    self.class.notify_observers(:after_create_dns, {:application => self, :reply => reply})    
    reply
  end
  
  def destroy_dns
    reply = ResultIO.new
    self.class.notify_observers(:before_destroy_dns, {:application => self, :reply => reply})
    dns = StickShift::DnsService.instance
    begin
      dns.deregister_application(@name,@domain.namespace)
      if self.scalable
        # find the group instance where the web-cartridge is residing
        self.group_instance_map.keys.each { |ginst_name|
          ginst = self.group_instance_map[ginst_name]
          ginst.gears.each { |gear|
            dns.deregister_application(gear.name,@domain.namespace)
          }
        }
      end
      dns.publish
    ensure
      dns.close
    end
    self.class.notify_observers(:after_destroy_dns, {:application => self, :reply => reply})  
    reply
  end
  
  def recreate_dns
    reply = ResultIO.new
    self.class.notify_observers(:before_recreate_dns, {:application => self, :reply => reply})    
    dns = StickShift::DnsService.instance
    begin
      dns.deregister_application(@name,@domain.namespace)
      public_hostname = self.container.get_public_hostname
      dns.register_application(@name,@domain.namespace, public_hostname)
      dns.publish
    ensure
      dns.close
    end
    self.class.notify_observers(:after_recreate_dns, {:application => self, :reply => reply})    
    reply
  end
  
  def update_namespace(new_ns, old_ns)
    updated = true
    begin
      result = self.container.update_namespace(self, self.framework, new_ns, old_ns)
      if result.is_a?(Array)
        # result is an Array of Gear when the domain is altered with a scalable app. 
        # There are no cart commands for a domain alter for scalable app. So doing nothing here.
        result.each { |r|
#          process_cartridge_commands(r.cart_commands)
          updated = updated and (r.exitcode == 0)
        }
      else
        # For a jenkins app (jenkins is non-scalable), the JENKINS_URL environment variable is updated
        process_cartridge_commands(result.cart_commands)
        updated = result.exitcode == 0
      end
    rescue Exception => e
      updated = false
      Rails.logger.debug "Exception caught updating namespace #{e.message}"
      Rails.logger.debug "DEBUG: Exception caught updating namespace #{e.message}"
      Rails.logger.debug e.backtrace
    end
    return updated 
  end
  
  def add_alias(server_alias)
    self.aliases = [] unless self.aliases
    raise StickShift::UserException.new("Alias '#{server_alias}' already exists for '#{@name}'", 255) if self.aliases.include? server_alias
    reply = ResultIO.new
    begin
      self.aliases.push(server_alias)
      self.save      
      reply.append self.container.add_alias(self, self.gear, self.framework, server_alias)
    rescue Exception => e
      Rails.logger.debug e.message
      Rails.logger.debug e.backtrace.inspect
      reply.append self.container.remove_alias(self, self.gear, self.framework, server_alias)      
      self.aliases.delete(server_alias)
      self.save
      raise
    end
    reply
  end
  
  def remove_alias(server_alias)
    self.aliases = [] unless self.aliases
    reply = ResultIO.new
    begin
      reply.append self.container.remove_alias(self, self.gear, self.framework, server_alias)
    rescue Exception => e
      Rails.logger.debug e.message
      Rails.logger.debug e.backtrace.inspect
      raise
    ensure
      if self.aliases.include? server_alias
        self.aliases.delete(server_alias)
        self.save
      else
        raise StickShift::UserException.new("Alias '#{server_alias}' does not exist for '#{@name}'", 255, reply)
      end      
    end
    reply
  end
  
  def add_dependency(dep)
    reply = ResultIO.new
    self.class.notify_observers(:before_add_dependency, {:application => self, :dependency => dep, :reply => reply})
    # Create persistent storage app entry on configure (one of the first things)
    Rails.logger.debug "DEBUG: Adding embedded app info from persistant storage: #{@name}:#{dep}"
    self.cart_data = {} if @cart_data.nil?
    
    raise StickShift::UserException.new("#{dep} already embedded in '#{@name}'", 101) if self.embedded.include? dep
    if self.scalable
      raise StickShift::UserException.new("#{dep} cannot be embedded in scalable app '#{@name}'. Allowed cartridges: #{SCALABLE_EMBEDDED_CARTS.join(',')}", 108) if not SCALABLE_EMBEDDED_CARTS.include? dep
    end
    add_to_requires_feature(dep)
    begin
      reply.append self.configure_dependencies
      self.execute_connections
    rescue Exception=>e
      remove_from_requires_feature(dep)
      self.elaborate_descriptor
      cleanup_deleted_components
      self.save
      raise e
    end

    self.class.notify_observers(:after_add_dependency, {:application => self, :dependency => dep, :reply => reply})
    reply
  end
  
  def remove_dependency(dep)
    reply = ResultIO.new
    self.class.notify_observers(:before_remove_dependency, {:application => self, :dependency => dep, :reply => reply})
    self.embedded = {} unless self.embedded
        
    raise StickShift::UserException.new("#{dep} not embedded in '#{@name}', try adding it first", 101) unless self.embedded.include? dep
    remove_from_requires_feature(dep)
    reply.append self.configure_dependencies
    self.class.notify_observers(:after_remove_dependency, {:application => self, :dependency => dep, :reply => reply})
    reply
  end

  # Returns the first Gear object on which the application is running
  # @return [Gear]
  # @deprecated  
  def gear
    if self.group_instances.nil?
      elaborate_descriptor
    end
    
    if scalable
      self.group_instance_map.keys.each { |ginst_name|
        return self.group_instance_map[ginst_name].gears.first if ginst_name.include? self.proxy_cartridge
      }
    end

    group_instance = self.group_instances.first
    return nil unless group_instance
    
    return group_instance.gears.first
  end
  
  # Get the ApplicationContainerProxy object for the first gear the application is running on
  # @return [ApplicationContainerProxy]
  # @deprecated  
  def container
    return nil if self.gear.nil?
    return self.gear.get_proxy
  end
  
  # Get the name of framework cartridge in use by the application without the version suffix
  # @return [String]
  # @deprecated  
  def framework_cartridge  
    fcart = self.framework
    return fcart.split('-')[0..-2].join('-') unless fcart.nil?
    return nil
  end
  
  # Get the name of framework cartridge in use by the application
  # @return [String]
  # @deprecated  
  def framework
    framework_carts = CartridgeCache.cartridge_names('standalone')
    self.comp_instance_map.each { |cname, cinst|
      cartname = cinst.parent_cart_name
      return cartname if framework_carts.include? cartname
    }
    return nil
  end
  
  # Provide a list of direct dependencies of the application that are hosted on the same gear as the "framework" cartridge.
  # @return [Array<String>]
  # @deprecated  
  def embedded
    embedded_carts = CartridgeCache.cartridge_names('embedded')
    retval = {}
    self.comp_instance_map.values.each do |comp_inst|
      if embedded_carts.include?(comp_inst.parent_cart_name)
        retval[comp_inst.parent_cart_name] = {}
        retval[comp_inst.parent_cart_name] = {"info" => comp_inst.cart_data.first} unless comp_inst.cart_data.first.nil?
      end
    end
    retval
  end

  # Provide a way of updating the component information for a given cartridge
  # @deprecated
  def set_embedded_cart_info(cart_name, info)
    self.comp_instance_map.values.each do |comp_inst|
      comp_inst.cart_data = [info] if cart_name == comp_inst.parent_cart_name
    end
  end
  
  # Provides an array version of the component instance map for saving in the datastore.
  # @return [Array<Hash>]
  def comp_instances
    @comp_instance_map = {} if @comp_instance_map.nil?
    @comp_instance_map.values
  end
  
  # Rebuilds the component instance map from an array of hashes or objects
  # @param [Array<Hash>] data
  def comp_instances=(data)
    comp_instance_map_will_change!    
    @comp_instance_map = {} if @comp_instance_map.nil?
    data.each do |value|
      if value.class == ComponentInstance
        @comp_instance_map[value.name] = value
      else
        key = value["name"]            
        @comp_instance_map[key] = ComponentInstance.new
        @comp_instance_map[key].attributes=value
      end
    end
  end

  # Provides an array version of the group instance map for saving in the datastore.
  # @return [Array<Hash>]
  def group_instances
    @group_instance_map = {} if @group_instance_map.nil?
    values = @group_instance_map.values.uniq
    keys   = @group_instance_map.keys
    
    values.each do |group_inst|
      group_inst.reused_by = keys.clone.delete_if{ |k| @group_instance_map[k] != group_inst }
    end
    
    values
  end
  
  # Rebuilds the group instance map from an array of hashes or objects
  # @param [Array<Hash>] data
  def group_instances=(data)
    group_instance_map_will_change!    
    @group_instance_map = {} if @group_instance_map.nil?
    data.each do |value|
      if value.class == GroupInstance
        value.reused_by.each do |k|
          @group_instance_map[k] = value
        end
      else
        ginst = GroupInstance.new(self)
        ginst.attributes=value
        ginst.reused_by.each do |k|
          @group_instance_map[k] = ginst
        end
      end
    end
  end
   
  def get_name_prefix
    return "@@app"
  end

  def add_group_override(from, to)
    prof = @profile_name_map[@default_profile]
    prof.group_overrides = [] if prof.group_overrides.nil?
    prof.group_overrides << [from, to]
  end

  def create_group_override(from, to)
    # assuming from/to to be cartridge names as of now
    # this also means that one cannot issue a group override at a lower hierarchy 
    #   (e.g. some new cartridge that uses mysql inside it, and app wants to co-locate/re-use that mysql for app's use)
    # this also means that one cannot have two instances of the same cartridge
    from_cart = CartridgeCache.find_cartridge(from)
    raise StickShift::NodeException.new("Cartridge #{from} not found, while resolving group overrides.", "-101", ResultIO.new) if from_cart.nil?
    to_cart = CartridgeCache.find_cartridge(to)
    raise StickShift::NodeException.new("Cartridge #{to} not found, while resolving group overrides.", "-101", ResultIO.new) if to_cart.nil?
    begin 
      from_group = from_cart.find_profile(nil).groups[0]
      to_group = to_cart.find_profile(nil).groups[0]

      from_gpath = self.get_name_prefix + from_cart.get_name_prefix + from_group.get_name_prefix
      to_gpath = self.get_name_prefix + to_cart.get_name_prefix + to_group.get_name_prefix
      self.group_override_map = {} if self.group_override_map.nil?
      group_override_map[from_gpath] = to_gpath
      group_override_map[to_gpath] = from_gpath
    rescue Exception=>e
      raise StickShift::NodeException.new("Cannot co-locate #{to} and #{from}. Internal fault - #{e.message}", "-101", ResultIO.new)
    end
  end

  # Parse the descriptor and build or update the runtime descriptor structure
  def elaborate_descriptor
    self.group_instance_map = {} if group_instance_map.nil?
    self.comp_instance_map = {} if comp_instance_map.nil?
    self.working_comp_inst_hash = {}
    self.working_group_inst_hash = {}
    self.group_override_map = {} if self.group_override_map.nil?
    self.conn_endpoints_list = [] 
    default_profile = @profile_name_map[@default_profile]
    
    # generate_group_overrides(default_profile)
  
    default_profile.groups.each { |g|
      #gpath = self.name + "." + g.name
      gpath = self.get_name_prefix + g.get_name_prefix
      mapped_path = group_override_map[gpath] || ""
      gi = working_group_inst_hash[mapped_path]
      if gi.nil?
        gi = self.group_instance_map[gpath]
        if gi.nil?
          gi = GroupInstance.new(self, self.name, self.default_profile, g.name, gpath) 
        else
          gi.merge(self.name, self.default_profile, g.name, gpath)
        end
      else
        gi.merge(self.name, self.default_profile, g.name, gpath)
      end
      self.group_instance_map[gpath] = gi
      self.working_group_inst_hash[gpath] = gi
      gi.elaborate(default_profile, g, self.get_name_prefix, self)
    }
    
    # make connection_endpoints out of provided connections
    default_profile.connections.each { |conn|
      inst1 = ComponentInstance::find_component_in_cart(default_profile, self, conn.components[0], self.get_name_prefix)
      inst2 = ComponentInstance::find_component_in_cart(default_profile, self, conn.components[1], self.get_name_prefix)
      ComponentInstance::establish_connections(inst1, inst2, self)
    }
    # check self.comp_instance_map for component instances
    # check self.group_instance_map for group instances
    # check self.conn_endpoints_list for list of connection endpoints (fully resolved)
  
    # auto merge top groups
    auto_merge_top_groups(default_profile)
  
    # resolve group co-locations
    colocate_groups
    
    # get configure_order and start_order
    get_exec_order(default_profile)
  
    deleted_components_list = []
    self.comp_instance_map.each { |k,v| deleted_components_list << k if self.working_comp_inst_hash[k].nil?  }
    deleted_components_list
  end
  
  # Get path for checking application health
  # @return [String]
  def health_check_path
    case self.framework_cartridge
      when 'php'
        page = 'health_check.php'
      when 'perl'
        page = 'health_check.pl'
      else
        page = 'health'
    end
  end
  
private

  def cleanup_deleted_components
    # delete entries in {group,comp}_instance_map that do 
    # not exist in working_{group,comp}_inst_hash
    self.group_instance_map.delete_if { |k,v| 
      v.component_instances.delete(k) if self.working_comp_inst_hash[k].nil? and v.component_instances.include?(k)
      self.working_group_inst_hash[k].nil? 
    }
    self.comp_instance_map.delete_if { |k,v| self.working_comp_inst_hash[k].nil?  }
  end
  
  def get_exec_order(default_profile)
    self.configure_order = []
    default_profile.configure_order.each { |raw_c_name|
      cinst = ComponentInstance::find_component_in_cart(default_profile, self, raw_c_name, self.get_name_prefix)
      next if cinst.nil?
      ComponentInstance::collect_exec_order(self, cinst, self.configure_order)
      self.configure_order << cinst.name if not self.configure_order.include? cinst.name
    }
    default_profile.groups.each { |g|
      g.component_refs.each { |cr|
        cpath = self.get_name_prefix + cr.get_name_prefix(default_profile)
        cinst = self.comp_instance_map[cpath]
        ComponentInstance::collect_exec_order(self, cinst, self.configure_order)
        self.configure_order << cpath if not self.configure_order.include? cpath
      }
    }
    self.start_order = self.configure_order
  end
  
  def colocate_groups
    self.conn_endpoints_list.each { |conn|
      if conn.from_connector.type.match(/^FILESYSTEM/) or conn.from_connector.type.match(/^AFUNIX/)
        cinst1 = self.comp_instance_map[conn.from_comp_inst]
        ginst1 = self.group_instance_map[cinst1.group_instance_name]
        cinst2 = self.comp_instance_map[conn.to_comp_inst]
        ginst2 = self.group_instance_map[cinst2.group_instance_name]
        next if ginst1==ginst2
        # these two group instances need to be colocated
        #ginst1.merge(ginst2.cart_name, ginst2.profile_name, ginst2.group_name, ginst2.name, ginst2.component_instances)
        ginst1.merge_inst(ginst2)
        self.group_instance_map[cinst2.group_instance_name] = ginst1
      end
    }
  end
  
  def generate_group_overrides(default_profile)
    default_profile.group_overrides.each do |go|
      go_copy = go.dup
      n = go_copy.pop
      go_copy.each { |v|
        create_group_override(n,v)
      }
    end
    return
  end
  
  def auto_merge_top_groups(default_profile)
    return if self.scalable
    first_group = default_profile.groups[0]
    gpath = self.get_name_prefix + first_group.get_name_prefix
    gi = self.group_instance_map[gpath]
    first_group.component_refs.each { |comp_ref|
      cpath = self.get_name_prefix + comp_ref.get_name_prefix(default_profile)
      ci = self.comp_instance_map[cpath]
      ci.dependencies.each { |cdep|
        cdepinst = self.comp_instance_map[cdep]
        ginst = self.group_instance_map[cdepinst.group_instance_name]
        next if ginst==gi
        Rails.logger.debug "Auto-merging group #{ginst.name} into #{gi.name}"
        # merge ginst into gi
        #gi.merge(ginst.cart_name, ginst.profile_name, ginst.group_name, ginst.name, ginst.component_instances)
        gi.merge_inst(ginst)
        self.group_instance_map[cdepinst.group_instance_name] = gi
      }
    }
  end


  # Runs the provided block on a set of containers
  # @param [Array<Gear>] Array of containers to run the block on. If nil, will run on all containers.
  # @param [Boolean] fail_fast Stop running immediately if an exception is raised
  # @param [Block]
  # @return [<successful_runs, failed_runs>] List of containers where the runs succeeded/failed
  def run_on_gears(gears=nil, result_io = nil, fail_fast=true, &block)
    successful_runs = []
    failed_runs = []
    gears = self.gears if gears.nil?
    
    gears.each do |gear|
      begin
        retval = block.call(gear, result_io)
        successful_runs.push({:gear => gear, :return => retval})
      rescue Exception => e
        Rails.logger.error e.message
        Rails.logger.error e.inspect
        Rails.logger.error e.backtrace.inspect        
        failed_runs.push({:gear => gear, :exception => e})
        if (!result_io.nil? && e.kind_of?(StickShift::SSException) && !e.resultIO.nil?)
          result_io.append(e.resultIO)
        end
        if fail_fast
          raise Exception.new({:successful => successful_runs, :failed => failed_runs, :exception => e})
        end
      end
    end
    
    return successful_runs, failed_runs
  end
  
  def process_cartridge_commands(commands)
    result = ResultIO.new
    commands.each do |command_item|
      case command_item[:command]
      when "SYSTEM_SSH_KEY_ADD"
        key = command_item[:args][0]
        self.user.add_system_ssh_key(self.name, key)
      when "SYSTEM_SSH_KEY_REMOVE"
        self.user.remove_system_ssh_key(self.name)
      when "ENV_VAR_ADD"
        key = command_item[:args][0]
        value = command_item[:args][1]
        self.user.add_env_var(key,value)
      when "ENV_VAR_REMOVE"
        key = command_item[:args][0]
        self.user.remove_env_var(key)
      when "BROKER_KEY_ADD"
        iv, token = StickShift::AuthService.instance.generate_broker_key(self)
        iv = Base64::encode64(iv)
        token = Base64::encode64(token)
        self.user.add_save_job('adds', 'broker_auth_keys', [self.uuid, iv, token])
      when "BROKER_KEY_REMOVE"
        self.user.add_save_job('removes', 'broker_auth_keys', [self.uuid])
      end
    end
    if user.save_jobs
      user.save
    end
    result
  end
end
