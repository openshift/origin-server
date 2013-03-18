class KeysController < BaseController
  #GET /user/keys
  def index
    ssh_keys = Array.new
    unless @cloud_user.ssh_keys.nil? 
      @cloud_user.ssh_keys.each do |key|
        ssh_key = RestKey.new(key, get_url, nolinks)
        ssh_keys.push(ssh_key)
      end
    end
    render_success(:ok, "keys", ssh_keys, "Found #{ssh_keys.length} ssh keys")
  end

  #GET /user/keys/<id>
  def show
    id = params[:id]

    # validate the key name using regex to avoid a mongo call, if it is malformed
    if id !~ SshKey::KEY_NAME_COMPATIBILITY_REGEX
      return render_error(:not_found, "SSH key '#{id}' not found", 118)
    end

    begin
      key = @cloud_user.ssh_keys.find_by(name: id)
      return render_success(:ok, "key", RestKey.new(key, get_url, nolinks), "Found SSH key '#{id}'")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "SSH key '#{id}' not found", 118)
    end
  end

  #POST /user/keys
  def create
    content = params[:content]
    name = params[:name]
    type = params[:type]
    
    Rails.logger.debug "Creating key name:#{name} type:#{type} for user #{@cloud_user.login}"
    
    # key should should not end with a format, else URLs in response links will fail
    # blocking additional formats in case we decide to support them in the future
    match = /\A[\S]+(\.(json|xml|yml|yaml|html|xhtml))\z/.match(name)
    unless match.nil? or match.length != 3
      return render_error(:unprocessable_entity, "SSH key name '#{name}' cannot end with #{match[1]}", nil)
    end

    key = UserSshKey.new(name: name, type: type, content: content)
    if key.invalid?
      messages = get_error_messages(key)
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    end
    
    if @cloud_user.ssh_keys.where(name: name).count > 0
      return render_error(:conflict, "SSH key with name #{name} already exists. Use a different name or delete conflicting key and retry.", 120, "name")
    end
    
    if @cloud_user.ssh_keys.where(content: content).count > 0
      return render_error(:conflict, "Given public key is already in use. Use different key or delete conflicting key and retry.", 121, "content")
    end

    begin
      @cloud_user.add_ssh_key(key)
      ssh_key = RestKey.new(key, get_url, nolinks)
      render_success(:created, "key", ssh_key, "Created SSH key #{name}", true, nil, nil, 'IP' => request.remote_ip)
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, e.message, e.code)
    rescue Exception => e
      return render_exception(e)
    end
  end

  #PUT /user/keys/<id>
  def update
    id = params[:id]
    content = params[:content]
    type = params[:type]
    
    Rails.logger.debug "Updating key name:#{id} type:#{type} for user #{@cloud_user.login}"
    
    # validate the key name using regex to avoid a mongo call, if it is malformed
    if id !~ SshKey::KEY_NAME_COMPATIBILITY_REGEX or @cloud_user.ssh_keys.where(name: id).count == 0
      return render_error(:not_found, "SSH key '#{id}' not found", 118)
    end
    
    
    key = UserSshKey.new(name: id, type: type, content: content)
    if key.invalid?
      messages = get_error_messages(key)
      return render_error(:unprocessable_entity, nil, nil, nil, nil, messages)
    end

    begin
      @cloud_user.update_ssh_key(key)
      ssh_key = RestKey.new(key, get_url, nolinks)
      log_action(@log_tag, true, "Updated SSH key #{id}", 'IP' => request.remote_ip)
      @reply = new_rest_reply(:ok, "key", ssh_key)
      @reply.messages.push(Message.new(:info, "Updated SSH key with name #{id} for user #{@cloud_user.login}"))
      respond_with @reply, :status => @reply.status
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, e.message, e.code)
    rescue Exception => e
      log_action(@log_tag, false, "Failed to update SSH key #{id}: #{e.message}")
      Rails.logger.error e
      Rails.logger.error e.backtrace
      @reply = new_rest_reply(:internal_server_error)
      error_code = e.respond_to?('code') ? e.code : 1
      @reply.messages.push(Message.new(:error, "Failed to update SSH key #{id} for user #{@cloud_user.login} due to:#{e.message}", error_code) )
      respond_with @reply, :status => @reply.status
    end
  end

  #DELETE /user/keys/<id>
  def destroy
    id = params[:id]
    
    # validate the key name using regex to avoid a mongo call, if it is malformed
    if id !~ SshKey::KEY_NAME_COMPATIBILITY_REGEX or @cloud_user.ssh_keys.where(name: id).count == 0
      return render_error(:not_found, "SSH key '#{id}' not found", 118)
    end

    begin
      @cloud_user.remove_ssh_key(id)
      render_success(:no_content, nil, nil, "Deleted SSH key #{id}", true)
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, e.message, e.code)
    rescue Exception => e
      return render_exception(e)
    end
  end
  
  def set_log_tag
    @log_tag = get_log_tag_prepend + "KEY"
  end
end
