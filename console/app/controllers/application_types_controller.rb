class ApplicationTypesController < ConsoleController

  def index
    types = ApplicationType.all

    types.sort!

    @template_types, @framework_types = types.partition{ |t| t.template }

  end

  def show
    @application_type = ApplicationType.find params[:id]
    user_default_domain rescue nil
    @application = Application.new :as => current_user
    @gear_sizes = user_capabilities_gear_sizes
    @max_gears = user_max_gears
    @gears_used = user_consumed_gears
    @advanced = params[:advanced] == 'true'
  end
end
