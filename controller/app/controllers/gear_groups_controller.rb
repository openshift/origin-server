class GearGroupsController < BaseController
  include RestModelHelper
  before_filter :get_application, :get_servers
  # This is the regex for group instances ID
  # We need to ensure backward compatibility for fetches
  GROUP_INSTANCE_ID_COMPATIBILITY_REGEX = /\A[A-Za-z0-9]+\z/

  def index
    gear_states, result_io = @application.get_gear_states(state_timeout)
    include_endpoints = (params[:include] == "endpoints")
    group_instances = @application.group_instances_with_overrides.map{ |group_inst| get_rest_gear_group(group_inst, gear_states, @application, get_url, nolinks, include_endpoints, @servers)}
    render_success(:ok, "gear_groups", group_instances, "Showing gear groups for application '#{@application.name}' with domain '#{@application.domain_namespace}'", result_io)
  end

  def show
    gear_group_id = params[:id].presence
    include_endpoints = (params[:include] == "endpoints")
    # validate the gear group ID using regex to avoid a mongo call, if it is malformed
    if gear_group_id !~ GROUP_INSTANCE_ID_COMPATIBILITY_REGEX
      raise Mongoid::Errors::DocumentNotFound.new(GroupInstance, nil, [gear_group_id])
    end
    gear_states, result_io = @application.get_gear_states(state_timeout)
    group_instance = @application.group_instances_with_overrides.detect{ |i| i.instance._id === gear_group_id } or 
      raise Mongoid::Errors::DocumentNotFound.new(GroupInstance, nil, [gear_group_id])
    render_success(:ok, "gear_group", get_rest_gear_group(group_instance, gear_states, @application, get_url, nolinks, include_endpoints, @servers), "Showing gear group #{gear_group_id} for application '#{@application.name}' with domain '#{@application.domain_namespace}'", result_io)
  end
  protected
    def get_servers
      @servers ={}
      server_names = @application.group_instances_with_overrides.map{|gi| gi.instance.gears.flatten.collect{|gear| gear.server_identity}}.flatten
      District.where({"servers.name"=> {"$in"=> server_names}}).collect{|d| d.servers}.flatten.map{|server| @servers[server.name] = server}
      @servers
    end

    def state_timeout
      maximum_wait = params[:timeout].to_i
      maximum_wait == 0 ? nil : [maximum_wait, 120].min
    end
end
