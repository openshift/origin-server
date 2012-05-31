class ApplicationTypesController < ConsoleController

  def index
    types = ApplicationType.all :as => session_user
    @template_types, types = types.partition{|t| t.template}
    @framework_types, types = types.partition { |t| t.categories.include?(:framework) }
    @popular_types, types = types.partition { |t| t.categories.include?(:popular) }
  end

  def show
    @application_type = ApplicationType.find params[:id], :as => session_user
    @domain = Domain.find :first, :as => session_user
    @application = Application.new :as => session_user

    # hard code for now but we want to get this from the server eventually
    @gear_sizes = ["small"] # gear size choice only shows if there is more than
                            # one option
  end
end
