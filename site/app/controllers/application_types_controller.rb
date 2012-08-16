class ApplicationTypesController < ConsoleController

  def index
    types = ApplicationType.all

    types.sort!

    @template_types, @framework_types = types.partition{ |t| t.template }

  end

  def show
    @application_type = ApplicationType.find params[:id]
    user_default_domain rescue nil
    @application = Application.new :as => session_user

    # hard code for now but we want to get this from the server eventually
    @gear_sizes = ["small"] # gear size choice only shows if there is more than
                            # one option
  end
end
