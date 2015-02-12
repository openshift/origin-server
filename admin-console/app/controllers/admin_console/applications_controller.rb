module AdminConsole
  class ApplicationsController < ApplicationController
    def show
      @id = params[:id]
      #If a url is passed with http:// or https:// then get rid of it, one of the /'s is already stripped off by rails
      @id.gsub! /http(s)?:\//, ""
      @apps = Application.where(:$or => [{:_id => @id}, {:name => @id}, {"aliases.fqdn" => @id}])
      # if not found, attempt to match the default fqdn based on app name and domain
      if @apps.empty?
        @id.match(/^(\w+)-(\w+)/) do |m|
          domain = Domain.find_by :namespace => m[2]
          @apps = [domain.applications.find_by(:name => m[1])]
        end
      end
      raise Mongoid::Errors::DocumentNotFound.new(Application, {}, [@id]) if @apps.empty?
    end

    protected
      def page_not_found(e=nil, message=nil, alternatives=nil)
        message = "Application #{@id} not found"
        super(e, message, alternatives)
      end
  end
end
