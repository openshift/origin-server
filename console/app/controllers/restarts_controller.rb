class RestartsController < ConsoleController

  def show
    @application = Application.find(params[:application_id], :as => current_user)
  end

  def update
    @application = Application.find(params[:application_id], :as => current_user)

    if @application.restart!
      redirect_to @application, :flash => flash_messages(@application.messages, {:success => "The application '#{@application.name}' has been restarted"})
    else
      render :show
    end
  end

end
