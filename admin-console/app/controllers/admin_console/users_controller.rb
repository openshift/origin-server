module AdminConsole
  class UsersController < ApplicationController
    def show
      @id = params[:id]
      #TODO catch mongoid exception when user not found and render 404 page
      @user = CloudUser.find_by_identity @id
    end
    protected
      def page_not_found(e=nil, message=nil, alternatives=nil)
        message = "User #{@id} not found"
        super(e, message, alternatives)
      end
  end
end