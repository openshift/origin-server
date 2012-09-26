class ConsoleIndexController < ConsoleController
  def index
    redirect_to applications_path
  end
end
