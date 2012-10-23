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

    # Make sure we have the latest values for these
    # by forcing a refresh of user capabilities
    user_caps = user_capabilities :refresh => true
    @max_gears = user_caps[:max_gears]
    @gears_used = user_caps[:consumed_gears]
    @gear_sizes = user_caps[:gear_sizes]

    @advanced = params[:advanced] == 'true'
  end
end
