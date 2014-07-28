module AdminConsole
  class GearsController < ApplicationController
    def show
      @id = params[:id]
      app_and_gear = Application.find_by_gear_uuid @id
      @app = app_and_gear[0]
      @gear = app_and_gear[1]
      return page_not_found unless @gear.present?
      @server = District.find_server(@gear.server_identity)
    end

    protected

      def page_not_found(e=nil, message=nil, alternatives=nil)
        message = "Gear #{@id} not found"
        super(e, message, alternatives)
      end
  end
end
