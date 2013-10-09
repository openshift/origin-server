class GearGroupsController < BaseController
  include RestModelHelper
  before_filter :get_application
  # This is the regex for group instances ID
  # We need to ensure backward compatibility for fetches
  GROUP_INSTANCE_ID_COMPATIBILITY_REGEX = /\A[A-Za-z0-9]+\z/

  # GET /application/[application_id]/gear_groups
  def index
    gear_states = @application.get_gear_states()
    include_endpoints = (params[:include] == "endpoints")
    group_instances = @application.group_instances_with_scale.map{ |group_inst| get_rest_gear_group(group_inst, gear_states, @application, get_url, nolinks, include_endpoints)}
    render_success(:ok, "gear_groups", group_instances, "Showing gear groups for application '#{@application.name}' with domain '#{@application.domain_namespace}'")
  end

  # GET /application/[application_id]/gear-group/[id]
  def show
    gear_group_id = params[:id].presence
    include_endpoints = (params[:include] == "endpoints")
    # validate the gear group ID using regex to avoid a mongo call, if it is malformed
    if gear_group_id !~ GROUP_INSTANCE_ID_COMPATIBILITY_REGEX
      return render_error(:not_found, "Gear group '#{gear_group_id}' not found for application #{@application.name} on domain '#{@application.domain_namespace}'", 101)
    end
    gear_states = @application.get_gear_states()
    group_instance = @application.group_instances.find(gear_group_id)
    render_success(:ok, "gear_group", get_rest_gear_group(group_instance, gear_states, @application, get_url, nolinks, include_endpoints), "Showing gear group #{gear_group_id} for application '#{@application.name}' with domain '#{@application.domain_namespace}'")
  end
end
