class AppCartController < BaseController
  respond_to :xml, :json
  before_filter :authenticate, :check_version

  # GET /domains/[domain_id]/applications/[application_id]/cartridges
  def index
    domain_id = params[:domain_id]
    id = params[:application_id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "LIST_APP_CARTRIDGES")
    end
    
    begin
      application = Application.find_by(domain: domain, name: id)
      cartridges = application.component_instances.map{ |c| RestCartridge11.new(nil,CartridgeCache.find_cartridge(c.cartridge_name),application,c,get_url,nolinks) }
      render_success(:ok, "cartridges", cartridges, "LIST_APP_CARTRIDGES", "Listing cartridges for application #{id} under domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "LIST_APP_CARTRIDGES")
    end
  end
  
  # GET /domains/[domain_id]/applications/[application_id]/cartridges/[cartridge_id]
  def show
    domain_id = params[:domain_id]
    application_id = params[:application_id]
    id = params[:id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "SHOW_APP_CARTRIDGE")
    end
    
    begin
      application = Application.find_by(domain: domain, name: application_id)
      comp = application.component_instances.find_by(cartridge_name: id)
      cartridge = RestCartridge11.new(nil,CartridgeCache.find_cartridge(comp.cartridge_name),application,comp,get_url,nolinks)
      
      return render_success(:ok, "cartridge", cartridge, "SHOW_APP_CARTRIDGE", "Showing cartridge #{id} for application #{application_id} under domain #{domain_id}")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{application_id}' not found for domain '#{domain_id}'", 101, "SHOW_APP_CARTRIDGE")
    end
  end

  # POST /domains/[domain_id]/applications/[application_id]/cartridges
  def create
    domain_id = params[:domain_id]
    id = params[:application_id]
    name = params[:name]
    
    # :cartridge param is deprecated because it isn't consistent with
    # the rest of the apis which take :name. Leave it here because
    # some tools may still use it
    name = params[:cartridge] if name.nil?
    colocate_with = params[:colocate_with]

    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "EMBED_CARTRIDGE")
    end
    
    begin
      application = Application.find_by(domain: domain, name: id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "EMBED_CARTRIDGE")
    end

    begin
      app_requires = application.requires + [name]
      application.requires = app_requires
    rescue StickShift::UserException => e
      return render_error(:bad_request, "Invalid cartridge. #{e.message}", 109, "EMBED_CARTRIDGE", "cartridge")
    end
    
    if application.run_jobs
      cart_name = CartridgeCache.find_cartridge(name).name
      comp = application.component_instances.find_by(cartridge_name: cart_name)
      cartridge = RestCartridge11.new(nil,CartridgeCache.find_cartridge(comp.cartridge_name),application,comp,get_url,nolinks)
      return render_success(:created, "cartridge", cartridge, "EMBED_CARTRIDGE", nil, nil, nil, nil)
    else
      return render_success(:accepted, "cartridge", cartridge, "EMBED_CARTRIDGE", "Delayed installation for cartridge #{name} for application #{id} under domain #{domain_id}", true, :info)
    end
  end

  # DELETE /domains/[domain_id]/applications/[application_id]/cartridges/[cartridge_id]
  def destroy
    domain_id = params[:domain_id]
    id = params[:application_id]
    cartridge = params[:id]
    
    begin
      domain = Domain.find_by(owner: @cloud_user, namespace: domain_id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Domain #{domain_id} not found", 127, "REMOVE_CARTRIDGE")
    end
    
    begin
      application = Application.find_by(domain: domain, name: id)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Application '#{id}' not found for domain '#{domain_id}'", 101, "REMOVE_CARTRIDGE")
    end
    
    begin
      comp = application.component_instances.find_by(cartridge_name: cartridge)
      feature = application.get_feature(comp.cartridge_name, comp.component_name)
      if CartridgeCache.find_cartridge(cartridge).categories.include?("web_framework")
        raise StickShift::UserException.new("Invalid cartridge #{id}")
      end
      
      application.requires -= [feature]
    rescue StickShift::UserException => e
      return render_error(:bad_request, "Application is currently busy performing another operation. Please try again in a minute.", 129, "REMOVE_CARTRIDGE")
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:bad_request, "Cartridge #{cartridge} not embedded within application #{id}", 129, "REMOVE_CARTRIDGE")
    end
    
    if application.run_jobs      
      render_success(:ok, "application", application, "REMOVE_CARTRIDGE", "Removed #{cartridge} from application #{id}", true)
    else
      return render_success(:accepted, "cartridge", cartridge, "REMOVE_CARTRIDGE", "Delayed installation for cartridge #{name} for application #{id} under domain #{domain_id}", true, :info)
    end
  end
end
