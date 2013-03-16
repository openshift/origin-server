class AliasController < BaseController
  include RestModelHelper

  # GET /domains/[domain id]/applications
  def index
    domain_id = params[:domain_id]
    id = params[:application_id]

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "LIST_APP_ALIASES")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
      rest_aliases = []
      application.aliases.each do |a|
        rest_aliases << get_rest_alias(application, domain, a)
      end
      render_success(:ok, "aliases", rest_aliases, "LIST_APP_ALIASES", "Listing aliases for application #{id} under domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "LIST_APP_ALIASES")
    rescue Exception => e
      return render_error(:internal_server_error, "Failed to get aliases for application #{id} due to: #{e.message}", 1, "LIST_APP_ALIASES")
    end
  end
  
  # GET /domains/[domain_id]/applications/<id>
  def show   
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    id = params[:id]

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "SHOW_APP_ALIAS")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: application_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "SHOW_APP_ALIAS")
    end
    
    begin
      al1as = application.aliases.find_by(fqdn: id)
      render_success(:ok, "alias", get_rest_alias(application, domain, al1as), "SHOW_APP_ALIAS", "Showing alias #{id} for application #{application_id} under domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Alias #{id} not found for application '#{application_id}'", 173, "SHOW_APP_ALIAS")
    rescue Exception => e
      return render_error(:internal_server_error, "Failed to get alias #{server_alias} due to: #{e.message}", 1, "SHOW_APP_ALIAS")
    end
  end
  

  def create
    domain_id = params[:domain_id]
    id = params[:application_id]
    server_alias = params[:id] || params[:alias] 
    ssl_certificate = params[:ssl_certificate]
    private_key = params[:private_key]
    pass_phrase = params[:pass_phrase]
    
    if ssl_certificate and (@cloud_user.capabilities["private_ssl_certificates"].nil? or @cloud_user.capabilities["private_ssl_certificates"] != true)
      return render_error(:forbidden, "User is not authorized to add private SSL certificates", 175, "ADD_ALIAS")
    end
    
    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "ADD_ALIAS")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "ADD_ALIAS")
    end
    
    begin 
      reply = application.add_alias(server_alias, ssl_certificate, private_key, pass_phrase)
      rest_alias = get_rest_alias(application, domain, application.aliases.find_by(fqdn: server_alias))
      messages = []
      log_msg = "Added #{server_alias} to application #{id}"
      messages.push(Message.new(:info, reply.resultIO.string, 0, :result))
      return render_success(:created, "alias", rest_alias, "ADD_ALIAS", "Added #{server_alias} to application #{id}", nil, nil, messages)
    rescue OpenShift::UserException => e
      return render_error(:unprocessable_entity, e.message, e.code, "ADD_ALIAS", e.field)
    rescue Exception => e
      Rails.logger.error "Failed to add alias #{server_alias} due to: #{e.message}"
      return render_error(:internal_server_error, "Failed to add alias #{server_alias} due to: #{e.message}", 1, "ADD_ALIAS")
    end
  end
  
  def update
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    server_alias = params[:id]
    ssl_certificate = params[:ssl_certificate]
    private_key = params[:private_key]
    pass_phrase = params[:pass_phrase]
    
    if ssl_certificate and (@cloud_user.capabilities["private_ssl_certificates"].nil? or @cloud_user.capabilities["private_ssl_certificates"] != true)
      return render_error(:forbidden, "User is not authorized to add private SSL certificates", 175, "ADD_ALIAS")
    end

    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "UPDATE_ALIAS")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: application_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "UPDATE_ALIAS")
    end
    
    begin
      al1as = application.aliases.find_by(fqdn: server_alias)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Alias #{} not found for application '#{application_id}'", 173, "UPDATE_ALIAS")
    end
    
    begin 
      reply = application.update_alias(server_alias, ssl_certificate, private_key, pass_phrase)
      al1as = application.aliases.find_by(fqdn: server_alias)
      rest_alias = get_rest_alias(application, domain, al1as)
      messages = []
      log_msg = "Added #{server_alias} to application #{application_id}"
      messages.push(Message.new(:info, log_msg))
      messages.push(Message.new(:info, reply.resultIO.string, 0, :result))
      return render_success(:ok, "alias", rest_alias, "UPDATE_ALIAS", log_msg, nil, nil, messages)
    rescue OpenShift::UserException => e
      return render_error(:unprocessable_entity, e.message, e.code, "UPDATE_ALIAS", e.field)
    rescue Exception => e
      Rails.logger.error "Failed to add alias #{server_alias} due to: #{e.message}"
      return render_error(:internal_server_error, "Failed to update alias #{server_alias} due to: #{e.message}", 1, "UPDATE_ALIAS")
    end
  end
  
  def destroy
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    server_alias = params[:id]
    begin
      domain = Domain.find_by(owner: @cloud_user, canonical_namespace: domain_id.downcase)
      @domain_name = domain.namespace
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "DELETE_ALIAS")
    end

    begin
      application = Application.find_by(domain: domain, canonical_name: application_id.downcase)
      @application_name = application.name
      @application_uuid = application.uuid
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "DELETE_ALIAS")
    end
       
    begin
      app_alias = application.aliases.find_by(fqdn: server_alias)
      application.remove_alias(server_alias)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Alias #{server_alias} not found for application #{application_id}", 173, "DELETE_ALIAS")
    rescue OpenShift::UserException => e
      return render_error(:unprocessable_entity, e.message, e.code, "DELETE_ALIAS", e.field)
    rescue Exception => e
      return render_error(:internal_server_error, "Failed to delete alias #{server_alias} due to: #{e.message}", 1, "DELETE_ALIAS")
    end
    render_success(:no_content, "application", application, "DELETE_ALIAS", "Removed #{server_alias} from application #{application_id}", true)
  end
end
