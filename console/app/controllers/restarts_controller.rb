class RestartsController < ConsoleController

  def show
    @application = Application.find(params[:application_id], :as => current_user)
  end

  def update
    @application = Application.find(params[:application_id], :as => current_user)

    if @application.restart!
      message = @application.messages.first || "The application '#{@application.name}' has been restarted"
      redirect_to @application, :flash => {:success => message.to_s}
    else
      message = @application.errors[:base].presence || "The application '#{@application.name}' could not be restarted"
      redirect_to @application, :flash => {:error => message}
    end
  end

end
