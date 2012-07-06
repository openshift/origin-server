require 'helpers/rest/api_common'

class Param_V1 < BaseObj
  attr_accessor :name, :type, :description, :valid_options

  def initialize(name=nil, type=nil, valid_options=nil)
    self.name = name
    self.type = type
    self.description = nil
    valid_options = [valid_options] unless valid_options.kind_of?(Array)
    self.valid_options = valid_options || Array.new
  end

  def compare(obj)
    if (self.name != obj.name) ||
       (self.type != obj.type) ||
       ((self.valid_options.to_s.length > 0) && (self.valid_options.size > obj.valid_options.size))
      raise_ex("Link Param '#{self.name}' inconsistent")
    end
    self.valid_options.each do |opt|
      raise_ex("Link Param option '#{opt}' NOT found") unless obj.valid_options.include?(opt)
    end if self.valid_options.to_s.length > 0
  end
end

class OptionalParam_V1 < BaseObj
  attr_accessor :name, :type, :description, :valid_options, :default_value

  def initialize(name=nil, type=nil, valid_options=nil, default_value=nil)
    self.name = name
    self.type = type
    self.description = nil
    valid_options = [valid_options] unless valid_options.kind_of?(Array)
    self.valid_options = valid_options || Array.new
    self.default_value = default_value
  end

  def compare(obj)
    if (self.name != obj.name) ||
       (self.type != obj.type) ||
       ((self.valid_options.to_s.length > 0) && (self.valid_options.size > obj.valid_options.size)) ||
       (self.default_value != obj.default_value)
      raise_ex("Link Optional Param '#{self.name}' inconsistent")
    end
    self.valid_options.each do |opt|
      raise_ex("Link Param option '#{opt}' NOT found") unless obj.valid_options.include?(opt)
    end if self.valid_options.to_s.length > 0
  end
end

class Link_V1 < BaseObj
  attr_accessor :rel, :method, :href, :required_params, :optional_params                               
                                                                                                       
  def initialize(method=nil, href=nil, required_params=nil, optional_params=nil)
    self.rel = nil 
    self.method = method                                                                               
    self.href = href.to_s                                                                              
    self.required_params = required_params || Array.new                                                
    self.optional_params = optional_params || Array.new                                                
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
      end if self.links.keys
    end
  end
end

class BaseApi_V1 < BaseObj_V1
  attr_accessor :links

  def initialize
    self.links = {
         "API" => Link_V1.new("GET", "api"),
         "GET_USER" => Link_V1.new("GET", "user"),
         "GET_USER" => Link_V1.new("GET", "user"),
         "LIST_DOMAINS" => Link_V1.new("GET", "domains"),
         "ADD_DOMAIN" => Link_V1.new("POST", "domains", [
           Param_V1.new("id", "string")
          ]),
         "LIST_CARTRIDGES" => Link_V1.new("GET", "cartridges"),
         "LIST_TEMPLATES" => Link_V1.new("GET", "application_template"),
         "LIST_ESTIMATES" => Link_V1.new("GET", "estimates")
    }
  end
end

class RestUser_V1 < BaseObj_V1
  attr_accessor :login, :consumed_gears, :links                                                                         
                                                                                                       
  def initialize
    self.login = nil
    self.consumed_gears = 0
    self.links = {                                                                                         
      "LIST_KEYS" => Link_V1.new("GET", "user/keys"),                     
      "ADD_KEY" => Link_V1.new("POST", "user/keys", [                  
        Param_V1.new("name", "string"),                                        
        Param_V1.new("type", "string", ["ssh-rsa", "ssh-dss"]),                            
        Param_V1.new("content", "string"),      
      ])                                                                                              
    } 
  end

  def compare(obj)
    raise_ex("User 'login' NOT found") if obj.login.nil?
    super
  end                                                                                                  
end

class RestCartridge_V1 < BaseObj_V1
  attr_accessor :type, :name, :version, :license, :license_url, :tags, :website,
    :suggests, :help_topics, :links, :properties, :requires, :conflicts, :suggests, :depends
  
  def initialize(type=nil, name=nil)
    self.name = name
    self.type = type
    self.properties = {}
    if type == "embedded"
      self.links = {
        "GET" => Link_V1.new("GET", "/cartridges/#{name}"),
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
      }
    end
  end

  def valid
    raise_ex("Invalid cartridge type '#{self.type}'") if ((self.type != 'standalone') && (self.type != 'embedded'))
  end
end

class RestEstimates_V1 < BaseObj_V1
  attr_accessor :links

  def initialize
    self.links = {
      "GET_ESTIMATE" => Link_V1.new("GET", "estimates/application",
        [ Param_V1.new("descriptor", "string") ])
    }
  end
end

class RestApplicationEstimate_V1 < BaseObj_V1
  attr_accessor :components

  def initialize
    self.components = nil
  end
end

class RestApplicationTemplate_V1 < BaseObj_V1
  attr_accessor :uuid, :display_name, :descriptor_yaml, :git_url, :tags, :gear_cost, :metadata
  attr_accessor :links

  def initialize
    self.uuid, self.display_name, self.descriptor_yaml = nil, nil, nil
    self.git_url, self.tags, self.gear_cost, self.metadata = nil, nil, nil, nil
    self.links = nil
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
         OptionalParam_V1.new("template", "string"),
         OptionalParam_V1.new("scale", "boolean", [true, false], false),
         OptionalParam_V1.new("gear_profile", "string", ["small"], "small")]),
      "UPDATE" => Link_V1.new("PUT", "domains/#{id}",
        [ Param_V1.new("id", "string") ]),
      "DELETE" => Link_V1.new("DELETE", "domains/#{id}", nil,
        [ OptionalParam_V1.new("force", "boolean", [true, false], false) ])
    }
  end
end

class RestKey_V1 < BaseObj_V1
  attr_accessor :name, :content, :type, :links

  def initialize(name=nil, content=nil, type=nil)
    self.name = name
    self.content = content
    self.type = type
    self.links = {
      "GET" => Link_V1.new("GET", "user/keys/#{name}"),
      "UPDATE" => Link_V1.new("PUT", "user/keys/#{name}", [
        Param_V1.new("type", "string", ["ssh-rsa", "ssh-dss"]),
        Param_V1.new("content", "string") ]),
      "DELETE" => Link_V1.new("DELETE", "user/keys/#{name}")
    }
  end
end

class RestApplication_V1 < BaseObj_V1
  attr_accessor :framework, :creation_time, :uuid, :embedded, :aliases, :name, :gear_count, :links, :domain_id, :git_url, :app_url, :ssh_url, :gear_profile, :scalable, :health_check_path, :scale_min, :scale_max

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
    self.scale_min = 1
    self.scale_max = -1
    self.health_check_path = nil
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
      "EXPOSE_PORT" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "expose-port") ]),
      "CONCEAL_PORT" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "conceal-port") ]),
      "SHOW_PORT" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/events",
        [ Param_V1.new("event", "string", "show-port") ]),
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
      "DELETE" => Link_V1.new("DELETE", "domains/#{domain_id}/applications/#{name}"),
      "ADD_CARTRIDGE" => Link_V1.new("POST", "domains/#{domain_id}/applications/#{name}/cartridges",
        [ Param_V1.new("cartridge", "string") ]),
      "LIST_CARTRIDGES" => Link_V1.new("GET", "domains/#{domain_id}/applications/#{name}/cartridges")
    }
  end
end

class RestGear_V1 < BaseObj_V1
  attr_accessor :uuid, :components, :git_url

  def initialize(components=nil)
    self.uuid = nil
    self.components = components
    self.git_url = nil
  end
end

class RestGearGroup_V1 < BaseObj_V1
  attr_accessor :name, :gear_profile, :gears, :cartridges

  def initialize(name=nil)
    self.name = name
    self.gear_profile = nil
    self.gears = nil
    self.cartridges = nil
  end
end
