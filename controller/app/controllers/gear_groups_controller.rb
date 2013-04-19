class GearGroupsController < BaseController

  # This is the regex for group instances ID
  # We need to ensure backward compatibility for fetches
  GROUP_INSTANCE_ID_COMPATIBILITY_REGEX = /\A[A-Za-z0-9]+\z/

  # GET /domains/[domain_id]/applications/[application_id]/gear_groups
  def index
    domain_id = params[:domain_id]
    app_id = params[:application_id]

    # validate the domain name using regex to avoid a mongo call, if it is malformed
    if domain_id !~ Domain::DOMAIN_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "LIST_GEAR_GROUPS")
    end

    # validate the application name using regex to avoid a mongo call, if it is malformed
    if app_id !~ Application::APP_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'", 101, "LIST_GEAR_GROUPS")
    end

    begin
      domain = Domain.with(consistency: :eventual).find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "LIST_GEAR_GROUPS")
    end

    begin
      application = Application.with(consistency: :eventual).find_by(domain: domain, canonical_name: app_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid

      gear_states = application.get_gear_states()
      group_instances = application.group_instances_with_scale.map{ |group_inst| RestGearGroup.new(group_inst, gear_states, application, domain, get_url, nolinks)}
      render_success(:ok, "gear_groups", group_instances, "LIST_GEAR_GROUPS", "Showing gear groups for application '#{app_id}' with domain '#{domain_id}'")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'", 101, "LIST_GEAR_GROUPS")
    end
  end

  # GET /domains/[domain_id]/applications/[application_id]/gear_groups/[id]
  def show
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    gear_group_id = params[:id]

    # validate the domain name using regex to avoid a mongo call, if it is malformed
    if domain_id !~ Domain::DOMAIN_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "SHOW_GEAR_GROUP")
    end

    # validate the application name using regex to avoid a mongo call, if it is malformed
    if app_id !~ Application::APP_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "Application '#{app_id}' not found for domain '#{domain_id}'", 101, "SHOW_GEAR_GROUP")
    end

    # validate the gear group ID using regex to avoid a mongo call, if it is malformed
    if gear_group_id !~ GROUP_INSTANCE_ID_COMPATIBILITY_REGEX
      return render_error(:not_found, "Gear group '#{gear_group_id}' not found for application #{app_id} on domain '#{domain_id}'", 101, "SHOW_GEAR_GROUP")
    end

    begin
      domain = Domain.with(consistency: :eventual).find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "LIST_GEAR_GROUPS")
    end

    begin
      application = Application.with(consistency: :eventual).find_by(domain: domain, canonical_name: app_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
      gear_states = application.get_gear_states()
      group_instance = application.group_instances.find(gear_group_id)

      render_success(:ok, "gear_group", RestGearGroup.new(group_instance, gear_states, application, domain, get_url, nolinks) , "SHOW_GEAR_GROUP", "Showing gear group #{gear_group_id} for application '#{app_id}' with domain '#{domain_id}'")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Gear group '#{gear_group_id}' not found for application #{app_id} on domain '#{domain_id}'", 101, "SHOW_GEAR_GROUP")
    end
  end
end
