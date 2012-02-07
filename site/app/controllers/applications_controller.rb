require 'net/http'
require 'uri'
require 'cgi'
require 'set'

class ApplicationsController < ApplicationController
  before_filter :require_login

  @@max_tries = 5000

  def index
    @userinfo = ExpressUserinfo.new :rhlogin => session[:login],
                                    :ticket => session[:ticket]
    @userinfo.establish
    @app = ExpressApp.new

    app_params = params[:app_filter_params]
    @app_type_filter_value = app_params[:app_type_filter]
    @name_filter_value = app_params[:name_filter]

    @app_types = Set.new
    @filtered_app_info = {}

    @userinfo.app_info.each do |app_name, app|
      app_type = app['framework'].split('-')[0]
      @app_types << [app_type, app_type]
      if @selected_app_type_filter != ""
        @filtered_app_info[app_name] = app
      elsif @selected_app_type_filter == app_type
        @filtered_app_info[app_name] = app
      end
    end

    render
  end
end
