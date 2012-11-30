class KeysController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version

  #GET /user/keys
  def index
    ssh_keys = Array.new
    unless @cloud_user.ssh_keys.nil? 
      @cloud_user.ssh_keys.each do |key|
        ssh_key = RestKey.new(key, get_url, nolinks)
        ssh_keys.push(ssh_key)
      end
    end
    render_success(:ok, "keys", ssh_keys, "LIST_KEYS", "Found #{ssh_keys.length} ssh keys")
  end

  #GET /user/keys/<id>
  def show
    id = params[:id]
    begin
      key = @cloud_user.ssh_keys.find_by(name: id)
      return render_success(:ok, "key", RestKey.new(key, get_url, nolinks), "SHOW_KEY", "Found SSH key '#{id}'")
    rescue Mongoid::Errors::DocumentNotFound
      render_error(:not_found, "SSH key '#{id}' not found", 118, "SHOW_KEY")
    end
  end

  #POST /user/keys
  def create
    content = params[:content]
    name = params[:name]
    type = params[:type]
    
    Rails.logger.debug "Creating key name:#{name} type:#{type} for user #{@login}"

    key = SshKey.new(name: name, type: type, content: content)
    if key.invalid?
      messages = get_error_messages(key)
      return render_error(:unprocessable_entity, nil, nil, "ADD_KEY", nil, nil, messages)
    end
    
    if @cloud_user.ssh_keys.where(name: name).count > 0
      return render_error(:conflict, "SSH key with name #{name} already exists. Use a different name or delete conflicting key and retry.", 120, "ADD_KEY", "name")
    end
    
    if @cloud_user.ssh_keys.where(content: content).count > 0
      return render_error(:conflict, "Given public key is already in use. Use different key or delete conflicting key and retry.", 121, "ADD_KEY", "content")
    end

    begin
      @cloud_user.add_ssh_key(key)
      ssh_key = RestKey.new(key, get_url, nolinks)
      render_success(:created, "key", ssh_key, "ADD_KEY", "Created SSH key #{name}", true)
    rescue Exception => e
      return render_exception(e, "ADD_KEY")
    return
    end
  end

  #PUT /user/keys/<id>
  def update
    id = params[:id]
    content = params[:content]
    type = params[:type]
    
    Rails.logger.debug "Updating key name:#{id} type:#{type} for user #{@login}"
    key = SshKey.new(name: id, type: type, content: content)
    if key.invalid?
      messages = get_error_messages(key)
      return render_error(:unprocessable_entity, nil, nil, "UPDATE_KEY", nil, nil, messages)
    end

    if @cloud_user.ssh_keys.where(name: id).count == 0
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "UPDATE_KEY", false, "SSH key #{id} not found")
      @reply = RestReply.new(:not_found)
      @reply.messages.push(Message.new(:error, "SSH key not found", 118))
      respond_with @reply, :status => @reply.status
      return
    end

    begin
      @cloud_user.update_ssh_key(key)
      ssh_key = RestKey.new(key, get_url, nolinks)
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "UPDATE_KEY", true, "Updated SSH key #{id}")
      @reply = RestReply.new(:ok, "key", ssh_key)
      @reply.messages.push(Message.new(:info, "Updated SSH key with name #{id} for user #{@login}"))
      respond_with @reply, :status => @reply.status
    rescue Exception => e
      log_action(@request_id, @cloud_user._id, @cloud_user.login, "UPDATE_KEY", false, "Failed to update SSH key #{id}: #{e.message}")
      Rails.logger.error e
      Rails.logger.error e.backtrace
      @reply = RestReply.new(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, "Failed to update SSH key #{id} for user #{@login} due to:#{e.message}", error_code) )
      respond_with @reply, :status => @reply.status
    end
  end

  #DELETE /user/keys/<id>
  def destroy
    id = params[:id]
    if @cloud_user.ssh_keys.where(name: id).count == 0
      return render_error(:not_found, "SSH key '#{id}' not found", 118, "DELETE_KEY")
    end

    begin
      @cloud_user.remove_ssh_key(id)
       render_success(:no_content, nil, nil, "DELETE_KEY", "Deleted SSH key #{id}", true)
    rescue Exception => e
      return render_exception(e, "DELETE_KEY")
    end
  end
end
