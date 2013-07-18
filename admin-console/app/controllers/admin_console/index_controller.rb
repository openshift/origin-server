require_dependency "admin_console/application_controller"

module AdminConsole
  class IndexController < ApplicationController
    def index
      @summary_for_profile = Profile.all
    end
  end
end
