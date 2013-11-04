class BuildingController < ConsoleController

  include CostAware
  
  def show
    @application = Application.find(params[:application_id], :as => current_user)
    redirect_to new_application_building_path(@application) unless @application.builds?
  end

  def new
    @capabilities = user_capabilities
    @application = Application.find(params[:application_id], :as => current_user)
    @jenkins_server = if @application.building_app
        @application.domain.find_application(@application.building_app) if @application.building_app
      else
        Application.new({:name => 'jenkins'}, false)
      end
    @cartridge_type = CartridgeType.cached.all.find{ |c| c.tags.include? :ci_builder }
    @cartridge = Cartridge.new :name => @cartridge_type.name
  end

  def create
    @capabilities = user_capabilities
    @application = Application.find(params[:application_id], :as => current_user)
    @jenkins_server = @application.domain.find_application(@application.building_app) if @application.building_app
    @cartridge_type = CartridgeType.cached.all.find{ |c| c.tags.include? :ci_builder }
    @cartridge = Cartridge.new :name => @cartridge_type.name

    unless @jenkins_server
      framework = CartridgeType.cached.all.find{ |c| c.tags.include? :ci }
      @jenkins_server = Application.new(
        :name => (params[:application][:name] rescue ""),
        :cartridge => framework.name,
        :domain => @application.domain,
        :as => current_user)

      if @jenkins_server.save
        message = @jenkins_server.remote_results
      else
        render :new and return
      end
    end

    @cartridge.application = @application

    success, attempts = @cartridge.save, 1
    while (!success && @cartridge.has_exit_code?(157, :on => :cartridge) && attempts < 2)
      logger.debug "  Jenkins server could not be contacted, sleep and then retry\n    #{@cartridge.errors.inspect}"
      sleep(10)
      success = @cartridge.save
      attempts += 1
    end

    if success
      redirect_to application_building_path(@application), :flash => {:info_pre => @cartridge.remote_results.concat(message || []).concat(['Your application is now building with Jenkins.'])}
    else
      if @cartridge.has_exit_code?(157, :on => :cartridge)
        message = 'The Jenkins server is not yet registered with DNS. Please wait a few minutes before trying again.'
      else
        @cartridge.errors.full_messages.each{ |m| @jenkins_server.errors.add(:base, m) }
      end
      flash.now[:info_pre] = message
      render :new
    end
  end

  def delete
    @application = Application.find(params[:application_id], :as => current_user)
    redirect_to new_application_building_path(@application) unless @application.builds?
  end

  def destroy
    @application = Application.find(params[:application_id], :as => current_user)
    if @application.destroy_build_cartridge
      redirect_to application_path(@application), :flash => {:success => "#{@application.name} is no longer building through Jenkins."}
    else
      render :delete
    end
  end

  protected
    def active_tab
      :applications
    end  
end
