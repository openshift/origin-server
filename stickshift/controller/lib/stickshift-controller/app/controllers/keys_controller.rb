class KeysController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper
  #GET /user/keys
  def index
    ssh_keys = Array.new
    unless @cloud_user.ssh_keys.nil? 
      @cloud_user.ssh_keys.each do |name, key|
        ssh_key = RestKey.new(name, key["key"], key["type"], get_url)
        ssh_keys.push(ssh_key)
      end
    end
    log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "LIST_KEYS", true, "Found #{ssh_keys.length} ssh keys")
    @reply = RestReply.new(:ok, "keys", ssh_keys)
    respond_with @reply, :status => @reply.status
  end

  #GET /user/keys/<id>
  def show
    id = params[:id]
    if @cloud_user.ssh_keys
      @cloud_user.ssh_keys.each do |key_name, key|
        if key_name == id
          log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_KEY", true, "Found SSH key '#{id}'")
          @reply = RestReply.new(:ok, "key", RestKey.new(key_name, key["key"], key["type"], get_url))
          respond_with @reply, :status => @reply.status
        return
        end
      end
    end

    log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "SHOW_KEY", false, "SSH key '#{id}' not found")
    @reply = RestReply.new(:not_found)
    @reply.messages.push(Message.new(:error, "SSH key not found", 118))
    respond_with @reply, :status => @reply.status
  end

  #POST /user/keys
  def create
    content = params[:content]
    name = params[:name]
    type = params[:type]
    
    Rails.logger.debug "Creating key name:#{name} type:#{type} for user #{@login}"

    key = Key.new(name, type, content)
    if key.invalid?
      key_validation_errors = []
      @reply = RestReply.new(:unprocessable_entity)
      key.errors.keys.each do |field|
        error_messages = key.errors.get(field)
        error_messages.each do |error_message|
          key_validation_errors.push(error_message[:message])
          @reply.messages.push(Message.new(:error, error_message[:message], error_message[:exit_code], field))
        end
      end
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_KEY", false, "#{key_validation_errors.join('. ')}")
      respond_with @reply, :status => @reply.status
    return
    end
    #check to see if key already exists
    #if @cloud_user.ssh_keys && @cloud_user.ssh_keys.has_key?(name)
    #  @reply = RestReply.new(:conflict)
    #  @reply.messages.push(Message.new(:error, "SSH key with name #{name} already exists. Use a different name or delete conflicting key and retry.", 120, "name"))
    #  respond_with @reply, :status => @reply.status
    #  return
    #end
    
    if @cloud_user.ssh_keys
      @cloud_user.ssh_keys.each do |key_name, key|
        if key_name == name
          log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_KEY", false, "SSH key with name #{name} already exists")
          @reply = RestReply.new(:conflict)
          @reply.messages.push(Message.new(:error, "SSH key with name #{name} already exists. Use a different name or delete conflicting key and retry.", 120, "name"))
          respond_with @reply, :status => @reply.status
        return
        end
        if key["key"] == content
          log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_KEY", false, "Given public key is already in use")
          @reply = RestReply.new(:conflict)
          @reply.messages.push(Message.new(:error, "Given public key is already in use. Use different key or delete conflicting key and retry.", 121, "content"))
          respond_with @reply, :status => @reply.status
        return
        end
      end
    end


    begin
      @cloud_user.add_ssh_key(name, content, type)
      @cloud_user.save
      ssh_key = RestKey.new(name, @cloud_user.ssh_keys[name]["key"], @cloud_user.ssh_keys[name]["type"], get_url)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_KEY", true, "Created SSH key #{name}")
      @reply = RestReply.new(:created, "key", ssh_key)
      @reply.messages.push(Message.new(:info, "Created SSH key #{name} for user #{@login}"))
      respond_with @reply, :status => @reply.status
    rescue Exception => e
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "ADD_KEY", false, "Failed to create SSH key #{name} of type #{type}: #{e.message}")
      Rails.logger.error e
      @reply = RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, "Failed to create SSH key for user #{@login} due to:#{e.message}", error_code) )
      respond_with @reply, :status => @reply.status
    return
    end
  end

  #PUT /user/keys/<id>
  def update

    id = params[:id]
    content = params[:content]
    type = params[:type]
    
    Rails.logger.debug "Updating key name:#{id} type:#{type} for user #{@login}"
    key = Key.new(id, type, content)
    if key.invalid?
      key_validation_errors = []
      @reply = RestReply.new(:unprocessable_entity)
      key.errors.keys.each do |field|
        error_messages = key.errors.get(field)
        error_messages.each do |error_message|
          key_validation_errors.push(error_message[:message])
          @reply.messages.push(Message.new(:error, error_message[:message], error_message[:exit_code], field))
        end
      end
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_KEY", false, "#{key_validation_errors.join('. ')}")
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end

    if @cloud_user.ssh_keys.nil? or not @cloud_user.ssh_keys.has_key?(id)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_KEY", false, "SSH key #{id} not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(Message.new(:error, "SSH key not found", 118))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end

    begin
      @cloud_user.update_ssh_key(content, type, id)
      @cloud_user.save
      ssh_key = RestKey.new(id, @cloud_user.ssh_keys[id]["key"], @cloud_user.ssh_keys[id]["type"], get_url)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_KEY", true, "Updated SSH key #{id}")
      @reply = RestReply.new(:ok, "key", ssh_key)
      @reply.messages.push(Message.new(:info, "Updated SSH key with name #{id} for user #{@login}"))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    rescue Exception => e
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "UPDATE_KEY", false, "Failed to update SSH key #{id}: #{e.message}")
      Rails.logger.error e
      @reply = RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, "Failed to update SSH key #{id} for user #{@login} due to:#{e.message}", error_code) )
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end
  end

  #DELETE /user/keys/<id>
  def destroy
    id = params[:id]
    if @cloud_user.ssh_keys.nil? or not @cloud_user.ssh_keys.has_key?(id)
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_KEY", false, "SSH key #{id} not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(Message.new(:error, "SSH key not found", 118))
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end

    begin
      @cloud_user.remove_ssh_key(id)
      @cloud_user.save
      @reply = RestReply.new(:no_content)
      @reply.messages.push(Message.new(:info, "Deleted SSH key #{id} for user #{@login}"))
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_KEY", true, "Deleted SSH key #{id}")
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    rescue Exception => e
      Rails.logger.error e
      @reply = RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, "Failed to delete SSH key #{id} for user #{@login} due to:#{e.message}", error_code) )
      log_action(@request_id, @cloud_user.uuid, @cloud_user.login, "DELETE_KEY", false, "Failed to delete SSH key #{id}: #{e.message}")
      respond_with(@reply) do |format|
        format.xml { render :xml => @reply, :status => @reply.status }
        format.json { render :json => @reply, :status => @reply.status }
      end
    return
    end
  end
end
