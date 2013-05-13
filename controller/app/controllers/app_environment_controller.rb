class AppEnvironmentController < BaseController
  include RestModelHelper
  before_filter :get_domain, :get_application
  
  def index
    env_var_names = @application.app_env_var_names.map{ |e| RestEnvironmentVariable.new(e, @application, get_url, nolinks) }
    render_success(:ok, "environment_variable", env_var_names, "Listing environment variables set on application #{@application.name} under domain #{@domain.namespace}")
  end
  
  def create
    name = params[:id]
    value = params[:value]
    
    begin
      @application.add_app_env_var(name, value)
      
      return render_success(:created, "environment_variable", RestEnvironmentVariable.new(name, @application, get_url, nolinks), "Added variable #{name} to application #{@application.name}")
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Enviornment variable '#{name}' not found for application '#{@application.name}'", 101)
    rescue Exception => e
      return render_exception(e)
    end
  end
  
  def destroy
    name = params[:id]
    
    begin
      @application.remove_app_env_var(name)
      
      return render_success(:no_content, "environment_variable", name, "Removed variable #{name} from application #{@application.name}")
    rescue OpenShift::LockUnavailableException => e
      return render_error(:service_unavailable, "Application is currently busy performing another operation. Please try again in a minute.", e.code)
    rescue Mongoid::Errors::DocumentNotFound
      return render_error(:not_found, "Enviornment variable '#{name}' not found for application '#{@application.name}'", 101)
    rescue Exception => e
      return render_exception(e)
    end
  end
    
  def set_log_tag
    @log_tag = get_log_tag_prepend + "APP_ENVIRONMENT"
  end
end
  