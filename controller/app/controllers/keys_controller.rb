class KeysController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version
  include LegacyBrokerHelper

  #GET /user/keys
  def index
    ssh_keys = Array.new
    @cloud_user.ssh_keys.each do |name, key|
      ssh_key = RestKey.new(name, key["key"], key["type"], get_url, nolinks)
      ssh_keys.push(ssh_key)
    end if @cloud_user.ssh_keys
    render_success(:ok, "keys", ssh_keys, "LIST_KEYS", "Found #{ssh_keys.length} ssh keys") 
  end

  #GET /user/keys/<id>
  def show
    id = params[:id]
    @cloud_user.ssh_keys.each do |key_name, key|
      return render_success(:ok, "key", RestKey.new(key_name, key["key"], key["type"], get_url, nolinks),
                            "SHOW_KEY", "Found SSH key '#{id}'") if key_name == id
    end if @cloud_user.ssh_keys
    render_error(:not_found, "SSH key '#{id}' not found", 118, "SHOW_KEY")
  end

  #POST /user/keys
  def create
    content = params[:content]
    name = params[:name]
    type = params[:type]
    
    Rails.logger.debug "Creating key name:#{name} type:#{type} for user #{@login}"

    key = Key.new(name, type, content)
    if key.invalid?
      messages = get_error_messages(key)
      return render_error(:unprocessable_entity, nil, nil, "ADD_KEY", nil, nil, messages)
    end
    
    @cloud_user.ssh_keys.each do |key_name, key|
      return render_error(:conflict, "SSH key with name #{name} already exists. Use a different name or delete conflicting key and retry.",
                          120, "ADD_KEY", "name") if key_name == name
      return render_error(:conflict, "Given public key is already in use. Use different key or delete conflicting key and retry.",
                          121, "ADD_KEY", "content") if key["key"] == content
    end if @cloud_user.ssh_keys

    begin
      @cloud_user.add_ssh_key(name, content, type)
      @cloud_user.save
      ssh_key = RestKey.new(name, @cloud_user.ssh_keys[name]["key"], @cloud_user.ssh_keys[name]["type"], get_url, nolinks)
      render_success(:created, "key", ssh_key, "ADD_KEY", "Created SSH key #{name}", true)
    rescue Exception => e
      return render_exception(e, "ADD_KEY")
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
      messages = get_error_messages(key)
      return render_format_error(:unprocessable_entity, nil, nil, "UPDATE_KEY", nil, nil, messages)
    end

    return render_format_error(:not_found, "SSH key '#{id}' not found", 118,
                               "UPDATE_KEY") if !@cloud_user.ssh_keys or !@cloud_user.ssh_keys.has_key?(id)

    begin
      @cloud_user.update_ssh_key(content, type, id)
      @cloud_user.save
      ssh_key = RestKey.new(id, @cloud_user.ssh_keys[id]["key"], @cloud_user.ssh_keys[id]["type"], get_url, nolinks)
      render_format_success(:ok, "key", ssh_key, "UPDATE_KEY", "Updated SSH key #{id}", true)
    rescue Exception => e
      return render_format_exception(e, "UPDATE_KEY")
    end
  end

  #DELETE /user/keys/<id>
  def destroy
    id = params[:id]
    return render_format_error(:not_found, "SSH key '#{id}' not found", 118,
                               "DELETE_KEY") if !@cloud_user.ssh_keys or !@cloud_user.ssh_keys.has_key?(id)

    begin
      @cloud_user.remove_ssh_key(id)
      @cloud_user.save
      render_format_success(:no_content, nil, nil, "DELETE_KEY", "Deleted SSH key #{id}", true)
    rescue Exception => e
      return render_format_exception(e, "DELETE_KEY")
    end
  end
end
