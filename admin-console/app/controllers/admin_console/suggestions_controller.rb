require_dependency "admin_console/application_controller"

module AdminConsole
  class SuggestionsController < IndexController
    def index
      super # same stuff as the index controller for now

      @expanded = params[:expanded]
    end
  end
end
