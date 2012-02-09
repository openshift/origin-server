class ApplicationTypesController < ApplicationController
  def show
    @application_type = ApplicationType.find params[:id]
    @application = RestApi::Application.new
  end
end
