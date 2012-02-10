class ApplicationTypesController < ApplicationController
  layout 'console'
  before_filter :new_forms

  def show
    @application_type = ApplicationType.find params[:id]
    @application = RestApi::Application.new
  end
end
