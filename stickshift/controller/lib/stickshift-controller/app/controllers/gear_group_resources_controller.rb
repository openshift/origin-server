class GearGroupResourcesController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  
  def show
    index
  end
  
  # GET /domains/[domain-id]/applications/[application_id]/gear_groups/[id]/resources
  def index
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    gear_group_id = params[:gear_group_id]
    
    app = Application.find(@cloud_user, app_id)
    
    if app.nil?
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "LIST_GEAR_GROUP_RESOURCES", false, "Application '#{app_id}' for domain '#{domain_id}' not found")
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application not found.", 101)
      @reply.messages.push(message)
      respond_with @reply, :status => @reply.status
    else
      selected_gear_group = nil
      app.group_instances.each { |group_inst|
        if group_inst.uuid == gear_group_id
          selected_gear_group = group_inst
          break
        end
      }
      
      if selected_gear_group.nil?
        log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "LIST_GEAR_GROUP_RESOURCES", false, "Gear group '#{gear_group_id}' for application '#{app_id}' not found")
        @reply = RestReply.new(:not_found)
        message = Message.new(:error, "Gear group not found.", 163)
        @reply.messages.push(message)
        respond_with @reply, :status => @reply.status
      else
        quota = selected_gear_group.get_quota
        @reply = RestReply.new(:ok, "resources", RestGearGroupResources.new(selected_gear_group.uuid, quota[:storage]))
        log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_GEAR_GROUP_RESOURCES", true, "Listing gear group resources for group '#{gear_group_id}' for application '#{app_id}'")
        respond_with @reply, :status => @reply.status
      end
    end
  end

  # PUT /domains/[domain-id]/applications/[application_id]/gear_groups/[id]/resources
  def update
    domain_id = params[:domain_id]
    app_id = params[:application_id]
    gear_group_id = params[:gear_group_id]
    storage = params[:storage]
    
    num_storage = nil
    max_storage = @cloud_user.capabilities['max_storage_per_gear']

    if max_storage.nil?
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_GEAR_GROUP_RESOURCES", false, "User is not allowed to change storage quota")
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "You are not authorized to change the storage quota", 164)
      @reply.messages.push(message)
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
      return
    end
    
    begin 
      num_storage = Integer(storage)
    rescue => e
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_GEAR_GROUP_RESOURCES", false, "Invalid storage value provided: '#{storage}'")
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Invalid storage value provided", 165)
      @reply.messages.push(message)
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
      return
    end
    
    app = Application.find(@cloud_user, app_id)
    
    if app.nil?
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_GEAR_GROUP_RESOURCES", false, "Application '#{app_id}' for domain '#{domain_id}' not found")
      @reply = RestReply.new(:not_found)
      message = Message.new(:error, "Application not found.", 101)
      @reply.messages.push(message)
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
      return
    else
      selected_gear_group = nil
      app.group_instances.each { |group_inst|
        selected_gear_group = group_inst if group_inst.uuid == gear_group_id
        break
      }
      
      if selected_gear_group.nil?
        log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_GEAR_GROUP_RESOURCES", false, "Gear group '#{gear_group_id}' for application '#{app_id}' not found")
        @reply = RestReply.new(:not_found)
        message = Message.new(:error, "Gear group not found.", 163)
        @reply.messages.push(message)
        respond_with(@reply) do |format|
          format.xml { render :xml => @reply, :status => @reply.status }
          format.json { render :json => @reply, :status => @reply.status }
        end
        return
      else
        begin
          # find the minimum block size for the gear profile - use any gear in the group
          min_storage = selected_gear_group.get_cached_min_storage_in_gb()
          if num_storage < min_storage or num_storage > max_storage
            log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_GEAR_GROUP_RESOURCES", false, "User is not allowed to change storage quota")
            @reply = RestReply.new(:not_found)
            message = Message.new(:error, "Storage value must be between #{min_storage} and #{max_storage}", 166)
            @reply.messages.push(message)
            respond_with(@reply) do |format|
              format.xml { render :xml => @reply, :status => @reply.status }
              format.json { render :json => @reply, :status => @reply.status }
            end
            return
          end

          selected_gear_group.set_quota(num_storage, nil)
          app.save
        rescue Exception => e
          log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_GEAR_GROUP_RESOURCES", false, "Failed to update resources for gear group '#{gear_group_id}': #{e.message}")
          @reply = RestReply.new(:internal_server_error)
          error_code = e.respond_to?('code') ? e.code : 1
          @reply.messages.push(Message.new(:error, e.message, error_code))
          respond_with(@reply) do |format|
            format.xml { render :xml => @reply, :status => @reply.status }
            format.json { render :json => @reply, :status => @reply.status }
          end
          return
        end
        
        @reply = RestReply.new(:ok, "resources", RestGearGroupResources.new(selected_gear_group.uuid, selected_gear_group.get_quota()[:storage]))
        log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_GEAR_GROUP_RESOURCES", true, "Updating resources for group '#{gear_group_id}' for application '#{app_id}'")
        respond_with(@reply) do |format|
          format.xml { render :xml => @reply, :status => @reply.status }
          format.json { render :json => @reply, :status => @reply.status }
        end
      end
    end
  end
end