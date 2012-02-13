class ApplicationTypesController < ConsoleController

  def index
    types = ApplicationType.find :all
    @framework_types, types = types.partition { |t| t.categories.include?(:framework) }
    @popular_types, types = types.partition { |t| t.categories.include?(:popular) }
  end

  def show
    @application_type = ApplicationType.find params[:id]
    @application = Application.new :as => session_user
    Rails.logger.debug "#{@application.inspect} instance?=#{@application.domain_name}"
  end
end
