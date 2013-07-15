require_dependency "admin_console/application_controller"

module AdminConsole
  class ProfilesController < ApplicationController
    def show
      @id = params[:id]
      @profile = Profile.find @id
    end
  end
end