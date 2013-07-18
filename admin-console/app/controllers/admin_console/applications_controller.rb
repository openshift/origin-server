require_dependency "admin_console/application_controller"

module AdminConsole
  class ApplicationsController < ApplicationController
    def show
      @id = params[:id]
      #TODO catch mongoid exception when application not found and render 404 page
      #If a url is passed with http:// or https:// then get rid of it, one of the /'s is already stripped off by rails
      @id.gsub! /http(s)?:\//, ""
      begin
        @app = Application.find_by(:$or => [{:uuid => @id}, {:name => @id}, {"aliases.fqdn" => @id}])
      rescue Mongoid::Errors::DocumentNotFound => e
        #attempt to match the default fqdn based on app name and domain
        @id.match(/(.+)-([^\.]+)\./) do |m|
          domain = Domain.find_by :namespace => m[2]
          @app = domain.applications.find_by :name => m[1]
        end
        raise e unless defined? @app
      end
    end

    protected
      def page_not_found(e=nil, message=nil, alternatives=nil)
        message = "Application #{@id} not found"
        super(e, message, alternatives)
      end
  end
end