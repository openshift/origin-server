class RestartsController < ConsoleController

  def show
    user_default_domain
    @application = @domain.find_application params[:application_id]
  end

  def update
    user_default_domain
    @application = @domain.find_application params[:application_id]

    @application.restart!

    message = @application.messages.first || "The application '#{@application.name}' has been restarted"
    redirect_to @application, :flash => {:success => message}
  end

end
