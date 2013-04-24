class GearGroupsController < BaseController
  before_filter :get_domain, :get_application
  # This is the regex for group instances ID
  # We need to ensure backward compatibility for fetches
  GROUP_INSTANCE_ID_COMPATIBILITY_REGEX = /\A[A-Za-z0-9]+\z/

  # GET /domains/[domain_id]/applications/[application_id]/gear_groups
  def index
    begin
      gear_states = @application.get_gear_states()
      group_instances = @application.group_instances_with_scale.map{ |group_inst| RestGearGroup.new(group_inst, gear_states, @application, @domain, get_url, nolinks)}
      render_success(:ok, "gear_groups", group_instances, "Showing gear groups for application '#{@application.name}' with domain '#{@domain.namespace}'")
    rescue Exception => e
      Rails.logger.error "Failed to get gear groups due to: #{e.message} #{e.backtrace}"
      return render_error(:internal_server_error, "Failed to get gear groups for application #{@application.name} due to: #{e.message}", 1)
    end
  end

  # GET /domains/[domain_id]/applications/[application_id]/gear_groups/[id]
  def show
    gear_group_id = params[:id]
    # validate the gear group ID using regex to avoid a mongo call, if it is malformed
    if gear_group_id !~ GROUP_INSTANCE_ID_COMPATIBILITY_REGEX
      return render_error(:not_found, "Gear group '#{gear_group_id}' not found for application #{@application.name} on domain '#{@domain.namespace}'", 101)
    end
    begin
      gear_states = @application.get_gear_states()
      group_instance = @application.group_instances.find(gear_group_id)
      render_success(:ok, "gear_group", RestGearGroup.new(group_instance, gear_states, @application, @domain, get_url, nolinks), "Showing gear group #{gear_group_id} for application '#{@application.name}' with domain '#{@domain.namespace}'")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Gear group '#{gear_group_id}' not found for application #{@application.name} on domain '#{@domain.namespace}'", 101)
    rescue Exception => e
      Rails.logger.error "Failed to get gear group #{gear_group_id} due to: #{e.message} #{e.backtrace}"
      return render_error(:internal_server_error, "Failed to get gear group #{gear_group_id}  for application #{@application.name} due to: #{e.message}", 1)
    end
  end
  
  def set_log_tag
    @log_tag = get_log_tag_prepend + "GEAR_GROUP"
  end
end
