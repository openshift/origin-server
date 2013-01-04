require 'helpers/rest/api_models_v1'

class RestApi_V1 < RestApi

  def initialize(uri=nil, method="GET")
    super(uri, method)
    self.version = '1.0'
  end

  def compare(hash)
    raise_ex("Response 'type' Not found") if !defined?(hash['type'])
    raise_ex("Response 'type' mismatch " +
             "expected:#{self.response_type}, got:#{hash['type']}") if hash['type'] != self.response_type
    raise_ex("Response 'version' mismatch " +
             "expected:#{self.version}, got:#{hash['version']}") if hash['version'] != self.version
    raise_ex("Response 'status' incorrect " +
             "expected:#{self.response_status}, got:#{hash['status']}") if hash['status'] != self.response_status

    data = hash['data']
    case hash['type']
      when 'links'
        links_hash = { 'links' => data }
        obj = BaseApi_V1.to_obj(links_hash)
        self.response.compare(obj)
      when 'user'
        obj = RestUser_V1.to_obj(data)
        self.response.compare(obj)
      when 'environment'
        raise_ex("Environment response not a hash") unless data.kind_of?(Hash)
      when 'cartridges'
        data.each do |cart_hash|
          obj = RestCartridge_V1.to_obj(cart_hash)
          obj.valid
        end
      when 'descriptor'
        # no-op
      when 'domain'
        obj = RestDomain_V1.to_obj(data)
        self.response.compare(obj)
      when 'domains'
        data.each do |dom_hash|
          obj = RestDomain_V1.to_obj(dom_hash)
        end
      when 'key'
        obj = RestKey_V1.to_obj(data)
        self.response.compare(obj)
      when 'keys'
        obj = RestKey_V1.to_obj(data[0])
        self.response.compare(obj)
      when 'application'
        obj = RestApplication_V1.to_obj(data)
        self.response.compare(obj)
      when 'applications'
        obj = RestApplication_V1.to_obj(data[0])
        self.response.compare(obj)
      when 'cartridge'
        obj = RestCartridge_V1.to_obj(data)
        self.response.compare(obj)
      when 'gear'
        obj = RestGear_V1.to_obj(data)
        self.response.compare(obj)
      when 'gear_groups'
        data.each do |gear_group_hash|
          obj = RestGearGroup_V1.to_obj(gear_group_hash)
        end
      when 'gears'
        data.each do |gear_hash|
          obj = RestGear_V1.to_obj(gear_hash)
        end
      else
        raise_ex("Invalid Response type")
    end
  end
end

api_get_v1 = RestApi_V1.new("/api")
api_get_v1.response = BaseApi_V1.new
api_get_v1.response_type = "links"

environment_get_v1 = RestApi_V1.new("/environment")
environment_get_v1.response_type = "environment"

user_get_v1 = RestApi_V1.new("/user")
user_get_v1.response = RestUser_V1.new
user_get_v1.response_type = "user"

cartridge_list_get_v1 = RestApi_V1.new("/cartridges")
cartridge_list_get_v1.response_type = "cartridges"

domain_add_post_v1 = RestApi_V1.new("/domains", "POST")
dom_id = gen_uuid[0..9]
domain_add_post_v1.request['id'] = dom_id
domain_add_post_v1.response = RestDomain_V1.new(dom_id)
domain_add_post_v1.response_type = "domain"
domain_add_post_v1.response_status = "created"

domains_list_get_v1 = RestApi_V1.new("/domains")
domains_list_get_v1.response_type = "domains"

domain_get_v1 = RestApi_V1.new("/domains/#{dom_id}")
domain_get_v1.response = RestDomain_V1.new(dom_id)
domain_get_v1.response_type = "domain"

domain_put_v1 = RestApi_V1.new("/domains/#{dom_id}", "PUT")
dom_id = gen_uuid[0..9]
domain_put_v1.request['id'] = dom_id
domain_put_v1.response = RestDomain_V1.new(dom_id)
domain_put_v1.response_type = "domain"

keys_post_v1 = RestApi_V1.new("/user/keys", "POST")
kname, ktype, content = 'key1', 'ssh-rsa', 'abcdef'
keys_post_v1.request.merge!({ 'name' => kname, 'type' => ktype, 'content' => content })
keys_post_v1.response = RestKey_V1.new(kname, content, ktype)
keys_post_v1.response_type = "key"
keys_post_v1.response_status = "created"

keys_list_get_v1 = RestApi_V1.new("/user/keys")
keys_list_get_v1.response = RestKey_V1.new(kname, content, ktype)
keys_list_get_v1.response_type = "keys"

keys_get_v1 = RestApi_V1.new("/user/keys/#{kname}")
keys_get_v1.response = RestKey_V1.new(kname, content, ktype)
keys_get_v1.response_type = "key"

keys_put_v1 = RestApi_V1.new("/user/keys/#{kname}", "PUT")
nktype, ncontent = 'ssh-dss', '12345'
keys_put_v1.request.merge!({ 'content' => ncontent, 'type' => nktype })
keys_put_v1.response = RestKey_V1.new(kname, ncontent, nktype) 
keys_put_v1.response_type = "key"

app_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications", "POST")
app_name, app_type, app_scale, app_timeout = 'app1', 'php-5.3', true, 180
app_post_v1.request.merge!({ 'name' => app_name, 'cartridge' => app_type, 'scale' => app_scale })
app_post_v1.request_timeout = app_timeout
app_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_post_v1.response_type = 'application'
app_post_v1.response_status = 'created'

app_list_get_v1 = RestApi_V1.new("/domains/#{dom_id}/applications")
app_list_get_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_list_get_v1.response_type = 'applications'

app_get_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}")
app_get_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_get_v1.response_type = 'application'

app_descriptor_get_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/descriptor")
app_descriptor_get_v1.response_type = 'descriptor'

app_start_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
app_start_post_v1.request['event'] = 'start'
app_start_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_start_post_v1.response_type = "application"

app_restart_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
app_restart_post_v1.request['event'] = 'restart'
app_restart_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_restart_post_v1.response_type = "application"

app_stop_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
app_stop_post_v1.request['event'] = 'stop'
app_stop_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_stop_post_v1.response_type = "application"

app_force_stop_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
app_force_stop_post_v1.request['event'] = 'force-stop'
app_force_stop_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_force_stop_post_v1.response_type = "application"

app_add_alias_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
random=rand(100000)
app_alias = "myApp#{random}"
app_add_alias_post_v1.request.merge!({ 'event' => 'add-alias' , 'alias' => app_alias })
app_add_alias_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_add_alias_post_v1.response_type = "application"

app_remove_alias_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
app_remove_alias_post_v1.request.merge!({ 'event' => 'remove-alias' , 'alias' => app_alias })
app_remove_alias_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_remove_alias_post_v1.response_type = "application"

app_scale_up_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
app_scale_up_post_v1.request['event'] = 'scale-up'
app_scale_up_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_scale_up_post_v1.response_type = "application"

#app_scale_down_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
#app_scale_down_post_v1.request['event'] = 'scale-down'
#app_scale_down_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
#app_scale_down_post_v1.response_type = "application"

app_add_cart_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/cartridges", "POST")
embed_cart = 'mysql-5.1'
app_add_cart_post_v1.request.merge!({ 'name' => embed_cart, 'colocate_with' => nil })
app_add_cart_post_v1.response = RestCartridge_V1.new('embedded', embed_cart, app_name)
app_add_cart_post_v1.response_type = "cartridge"
app_add_cart_post_v1.response_status = "created"

#app_expose_port_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
#app_expose_port_post_v1.request['event'] = 'expose-port'
#app_expose_port_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
#app_expose_port_post_v1.response_type = "application"

#app_show_port_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
#app_show_port_post_v1.request['event'] = 'show-port'
#app_show_port_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
#app_show_port_post_v1.response_type = "application"

#app_gear_get_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/gears")
#app_gear_get_v1.response_type = 'gears'

app_gear_groups_get_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/gear_groups")
app_gear_groups_get_v1.response_type = 'gear_groups'

#app_conceal_port_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/events", "POST")
#app_conceal_port_post_v1.request['event'] = 'conceal-port'
#app_conceal_port_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
#app_conceal_port_post_v1.response_type = "application"

app_cart_list_get_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/cartridges")
app_cart_list_get_v1.response_type = "cartridges"

app_cart_get_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/cartridges/#{embed_cart}")
app_cart_get_v1.response = RestCartridge_V1.new('embedded', embed_cart, app_name)
app_cart_get_v1.response_type = "cartridge"

app_cart_start_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/cartridges/#{embed_cart}/events", "POST")
app_cart_start_post_v1.request['event'] = 'start'
app_cart_start_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_cart_start_post_v1.response_type = "application"

app_cart_restart_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/cartridges/#{embed_cart}/events", "POST")
app_cart_restart_post_v1.request['event'] = 'restart'
app_cart_restart_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_cart_restart_post_v1.response_type = "application"

app_cart_reload_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/cartridges/#{embed_cart}/events", "POST")
app_cart_reload_post_v1.request['event'] = 'reload'
app_cart_reload_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_cart_reload_post_v1.response_type = "application"

app_cart_stop_post_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/cartridges/#{embed_cart}/events", "POST")
app_cart_stop_post_v1.request['event'] = 'stop'
app_cart_stop_post_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
app_cart_stop_post_v1.response_type = "application"

#app_cart_delete_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}/cartridges/#{embed_cart}", "DELETE")
#app_cart_delete_v1.response = RestApplication_V1.new(app_name, app_type, dom_id, app_scale)
#app_cart_delete_v1.response_type = "application"

app_delete_v1 = RestApi_V1.new("/domains/#{dom_id}/applications/#{app_name}", "DELETE")

keys_delete_v1 = RestApi_V1.new("/user/keys/#{kname}", "DELETE")

domain_delete_v1 = RestApi_V1.new("/domains/#{dom_id}", "DELETE")

REST_CALLS_V1 = [
                  api_get_v1,
                  environment_get_v1,
                  user_get_v1,
                  cartridge_list_get_v1,
                  domain_add_post_v1,
                  domains_list_get_v1,
                  domain_get_v1,
                  domain_put_v1,
                  keys_post_v1,
                  keys_list_get_v1,
                  keys_get_v1,
                  keys_put_v1,
                  app_post_v1,
                  app_list_get_v1,
                  app_get_v1,
                  app_descriptor_get_v1,
                  app_start_post_v1,
                  app_restart_post_v1,
                  app_stop_post_v1,               
                  app_force_stop_post_v1,
                  app_add_alias_post_v1, 
                  app_remove_alias_post_v1, 
                  app_scale_up_post_v1, 
                  #app_scale_down_post_v1,
                  app_add_cart_post_v1, 
                  #app_expose_port_post_v1, 
                  #app_show_port_post_v1,
                  #app_gear_get_v1, 
                  app_gear_groups_get_v1,
                  #app_conceal_port_post_v1,
                  app_cart_list_get_v1, 
                  app_cart_get_v1,
                  app_cart_start_post_v1, 
                  app_cart_restart_post_v1, 
                  app_cart_reload_post_v1, 
                  app_cart_stop_post_v1, 
                  #app_cart_delete_v1, 
                  app_delete_v1,
                  keys_delete_v1,
                  domain_delete_v1
                ]
