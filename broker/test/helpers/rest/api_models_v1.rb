require 'helpers/rest/api_common'

class Param_V1 < BaseObj
  attr_accessor :name, :type, :description, :valid_options, :invalid_options

  def initialize(name=nil, type=nil, valid_options=nil, invalid_options=nil)
    self.name = name
    self.type = type
    self.description = nil
    self.valid_options = Array(valid_options)
    self.invalid_options = Array(invalid_options)
  end

  def compare(obj)
    if (self.name != obj.name) ||
       (self.type != obj.type) ||
       ((self.valid_options.length > 0) && (self.valid_options.size > obj.valid_options.size)) ||
       ((self.invalid_options.length > 0) && (self.invalid_options.size > obj.invalid_options.size))
      raise_ex("Link Param '#{self.name}' inconsistent in #{obj.inspect}")
    end
    self.valid_options.each do |opt|
      raise_ex("Link Param option '#{opt}' NOT found in #{obj.inspect}") unless obj.valid_options.include?(opt)
    end if self.valid_options.length > 0
  end
end

class OptionalParam_V1 < BaseObj
  attr_accessor :name, :type, :description, :valid_options, :default_value

  def initialize(name=nil, type=nil, valid_options=nil, default_value=nil)
    self.name = name
    self.type = type
    self.description = nil
    valid_options = Array(valid_options)
    self.valid_options = Array(valid_options)
    self.default_value = default_value
  end

  def compare(obj)
    if (self.name != obj.name) ||
       (self.type != obj.type) ||
       ((self.valid_options.length > 0) && (self.valid_options.size > obj.valid_options.size)) ||
       (self.default_value && (self.default_value != obj.default_value))
      raise_ex("Link Optional Param '#{self.name}' inconsistent")
    end
    self.valid_options.each do |opt|
      raise_ex("Link Param option '#{opt}' NOT found") unless obj.valid_options.include?(opt)
    end if self.valid_options.length > 0
  end
end

class Link_V1 < BaseObj
  attr_accessor :rel, :method, :href, :required_params, :optional_params

  def initialize(method=nil, href=nil, required_params=nil, optional_params=nil)
    self.rel = nil
    self.method = method
    self.href = href.to_s
    self.required_params = Array(required_params)
    self.optional_params = Array(optional_params)
  end

  def self.to_obj(hash)
    obj = super(hash)
    obj_req_params = []
    obj.required_params.each do |param|
      p = Param_V1.to_obj(param)
      obj_req_params.push(p)
    end if obj.required_params
    obj.required_params = obj_req_params
    obj_opt_params = []
    obj.optional_params.each do |param|
      p = OptionalParam_V1.to_obj(param)
      obj_opt_params.push(p)
    end if obj.optional_params
    obj.optional_params = obj_opt_params
    obj
  end

  def compare(obj)
    href_size = self.href.size
    if (self.method != obj.method) || (self.href !=  obj.href[-href_size..-1])
      raise_ex("Link 'method' or 'href' failed to match")
    end

    if self.required_params.empty?
      raise_ex("New 'required_params' found for Link") if !obj.required_params.empty?
    else
      raise_ex("Missing 'required_params' found for Link") if obj.required_params.empty?
      req_params = self.required_params.sort { |a,b| a.name.downcase <=> b.name.downcase }
      obj_req_params = obj.required_params.sort { |a,b| a.name.downcase <=> b.name.downcase }
      for i in 0..req_params.size-1
        req_params[i].compare(obj_req_params[i])
      end
    end

    if self.optional_params.empty?
      raise_ex("New 'optional_params' found for Link") if !obj.optional_params.empty?
    else
      raise_ex("Missing 'optional_params' found for Link") if obj.optional_params.empty?
      opt_params = self.optional_params.sort { |a,b| a.name.downcase <=> b.name.downcase }
      obj_opt_params = obj.optional_params.sort { |a,b| a.name.downcase <=> b.name.downcase }
      for i in 0..opt_params.size-1
        opt_params[i].compare(obj_opt_params[i])
      end
    end
  end
end

class BaseObj_V1 < BaseObj
  def self.to_obj(hash)
    return nil if hash.to_s.length == 0

    obj = super(hash)
    if defined?(obj.links)
      obj_links = {}
      obj.links.each do |lname, link_hash|
        obj_links[lname] = Link_V1.to_obj(link_hash)
      end if obj.links
      obj.links = obj_links
    end
    obj
  end

  def compare(obj)
    if defined?(obj.links)
      self.links.keys.each do |lname|
        raise_ex("Link '#{lname}' missing") unless obj.links[lname]
        self.links[lname].compare(obj.links[lname])
      end if self.links && self.links.keys
    end
  end
end

class BaseApi_V1 < BaseObj_V1
  attr_accessor :links

  def initialize
    self.links = {
         "API" => Link_V1.new("GET", "api"),
         "GET_ENVIRONMENT" => Link_V1.new("GET", "environment"),
         "GET_USER" => Link_V1.new("GET", "user"),
         "LIST_DOMAINS" => Link_V1.new("GET", "domains"),
         "ADD_DOMAIN" => Link_V1.new("POST", "domains", [
           Param_V1.new("id", "string")
          ]),
         "LIST_CARTRIDGES" => Link_V1.new("GET", "cartridges")
    } unless $nolinks
  end
end

class RestUser_V1 < BaseObj_V1
  attr_accessor :login, :consumed_gears, :max_gears, :capabilities, :plan_id, :usage_account_id, :links
  KEY_TYPES = ['ssh-rsa', 'ssh-dss', 'ssh-rsa-cert-v01@openssh.com', 'ssh-dss-cert-v01@openssh.com',
               'ssh-rsa-cert-v00@openssh.com', 'ssh-dss-cert-v00@openssh.com']

  def initialize
    self.login = nil
    self.consumed_gears = 0
    self.max_gears = 3
    self.capabilities = nil
    self.plan_id = nil
    self.usage_account_id = nil
    self.links = {
      "LIST_KEYS" => Link_V1.new("GET", "user/keys"),
      "ADD_KEY" => Link_V1.new("POST", "user/keys", [
        Param_V1.new("name", "string"),
        Param_V1.new("type", "string", KEY_TYPES), 
        Param_V1.new("content", "string"), 
      ]) 
    } unless $nolinks 
  end

  def compare(obj)
    raise_ex("User 'login' NOT found") if obj.login.nil?
    super
  end
end

class RestEmbeddedCartridge_V1 < BaseObj_V1
  attr_accessor :type, :name, :links, :properties, :status_messages

  def initialize(type=nil, name=nil, app=nil)
    self.name = name
    self.type = type
    self.properties = {}
    self.status_messages = nil

    if app and !$nolinks
      self.links = {
          "GET" => Link_V1.new("GET", "/cartridges/#{name}")
      }
      self.links.merge!({
        "START" => Link_V1.new("POST", "/cartridges/#{name}/events", [
          Param_V1.new("event", "string", "start")
        ]),
        "STOP" => Link_V1.new("POST", "/cartridges/#{name}/events", [
          Param_V1.new("event", "string", "stop")
        ]),
        "RESTART" => Link_V1.new("POST", "/cartridges/#{name}/events", [
          Param_V1.new("event", "string", "restart")
        ]),
        "RELOAD" => Link_V1.new("POST", "/cartridges/#{name}/events", [ 
          Param_V1.new("event", "string", "reload")
        ]),
        "DELETE" => Link_V1.new("DELETE", "/cartridges/#{name}")
      }) if type == "embedded"
    end
  end

  def valid(app=nil)
    raise_ex("Invalid cartridge type '#{self.type}'")  if ((self.type != 'standalone') && (self.type != 'embedded'))
    if app
      raise_ex("Invalid cartridge type '#{self.type}'")  if self.type != 'embedded'
      raise_ex("Invalid cartridge type '#{self.name}'") if self.name.start_with? "haproxy"
    end
  end
end

class RestApplicationEstimate_V1 < BaseObj_V1
  attr_accessor :components

  def initialize
    self.components = nil
  end
end

class RestDomain_V1 < BaseObj_V1
  attr_accessor :id, :suffix, :links

  def initialize(id=nil)
    self.id = id
    self.suffix = nil
    self.links = {
      "GET" => Link_V1.new("GET", "domains/#{id}"),
      "LIST_APPLICATIONS" => Link_V1.new("GET", "domains/#{id}/applications"),
      "ADD_APPLICATION" => Link_V1.new("POST", "domains/#{id}/applications",
        [Param_V1.new("name", "string")],
        [OptionalParam_V1.new("cartridge", "string"),
         OptionalParam_V1.new("scale", "boolean", [true, false], false),
         OptionalParam_V1.new("gear_profile", "string"),
         OptionalParam_V1.new("initial_git_url", "string", ["*", "empty"])
        ]),
      "UPDATE" => Link_V1.new("PUT", "domains/#{id}",
        [ Param_V1.new("id", "string") ]),
      "DELETE" => Link_V1.new("DELETE", "domains/#{id}", nil,
        [ OptionalParam_V1.new("force", "boolean", [true, false], false) ])
    } unless $nolinks
  end
end

class RestKey_V1 < BaseObj_V1
  attr_accessor :name, :content, :type, :links
  KEY_TYPES = ['ssh-rsa', 'ssh-dss', 'ssh-rsa-cert-v01@openssh.com', 'ssh-dss-cert-v01@openssh.com',
               'ssh-rsa-cert-v00@openssh.com', 'ssh-dss-cert-v00@openssh.com']

  def initialize(name=nil, content=nil, type=nil)
    self.name = name
    self.content = content
    self.type = type
    self.links = {
      "GET" => Link_V1.new("GET", "user/keys/#{name}"),
      "UPDATE" => Link_V1.new("PUT", "user/keys/#{name}", [
        Param_V1.new("type", "string", KEY_TYPES),
        Param_V1.new("content", "string") ]),
      "DELETE" => Link_V1.new("DELETE", "user/keys/#{name}")
    } unless $nolinks
  end
end

class RestApplication_V1 < BaseObj_V1
  attr_accessor :framework, :creation_time, :uuid, :embedded, :aliases, :name, :gear_count, :links, :domain_id, :git_url, :app_url, :ssh_url, :gear_profile, :scalable, :health_check_path, :scale_min, :scale_max, :building_with, :building_app, :build_job_url, :auto_deploy, :deployment_branch, :keep_deployments, :deployment_type

  def initialize(name=nil, framework=nil, domain_id=nil, scalable=nil)
    self.name = name
    self.framework = framework
    self.creation_time = nil
    self.uuid = nil
    self.embedded = nil
    self.aliases = nil
    self.gear_count = nil
    self.domain_id = domain_id
    self.gear_profile = nil
    self.git_url = nil
    self.app_url = nil
    self.ssh_url = nil
    self.scalable = scalable
    self.health_check_path = nil
    self.auto_deploy = false
    self.deployment_branch = 'master'
    self.keep_deployments = 1
    self.deployment_type = 'git'
    self.links = {
      "GET" => Link_V1.new("GET", "domains/#{domain_id}/applications/#{name}"),
      "GET_DESCRIPTOR" => Link_V1.new("GET", "domains/#{domain_id}/applications/#{name}/descriptor"),
      "GET_GEARS" => Link_V1.new("GET", "domains/#{domain_id}/applications/#{name}/gears"),
      "GET_GEAR_GROUPS" => Link_V1.new("GET", "domains/#{domain_id}/applications/#{name}/gear_groups"),
      "START" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "start") ]),
      "STOP" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "stop") ]),
      "RESTART" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "restart") ]),
      "FORCE_STOP" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "force-stop") ]),
      "ADD_ALIAS" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "add-alias"),
          Param_V1.new("alias", "string") ]),
      "REMOVE_ALIAS" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "remove-alias"),
          Param_V1.new("alias", "string") ]),
      "SCALE_UP" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "scale-up") ]),
      "SCALE_DOWN" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "scale-down") ]),
      "TIDY" => Link_V1.new("POST", "domains/#{@domain_id}/applications/#{@name}/events",
        [ Param_V1.new("event", "string", "tidy") ]),
      "RELOAD" => Link_V1.new("POST", "domains/#{@domain_id}/applications/#{@name}/events",
        [ Param_V1.new("event", "string", "reload") ]),
      "DELETE" => Link_V1.new("DELETE", "domains/#{domain_id}/applications/#{name}"),
      "ADD_CARTRIDGE" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/cartridges",
        [ Param_V1.new("cartridge", "string") ]),
      "LIST_CARTRIDGES" => Link_V1.new("GET", "domains/#{domain_id}/applications/#{name}/cartridges")
    } unless $nolinks
  end
end

class RestGear_V1 < BaseObj_V1
  attr_accessor :uuid, :components

  def initialize(components=nil)
    self.uuid = nil
    self.components = components
  end
end

class RestGearGroup_V1 < BaseObj_V1
  attr_accessor :uuid, :name, :gear_profile, :gears, :cartridges, :scales_to, :scales_from, :base_gear_storage, :additional_gear_storage

  def initialize(name=nil)
    self.uuid = uuid
    self.name = name
    self.gear_profile = nil
    self.gears = nil
    self.cartridges = nil
    self.base_gear_storage = nil
    self.additional_gear_storage = nil
    self.scales_from = nil
    self.scales_to = nil
  end
end
