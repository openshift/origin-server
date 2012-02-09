require 'net/http'
require 'uri'
require 'cgi'
require 'set'

class ApplicationsController < ApplicationController
  before_filter :require_login

  @@max_tries = 5000

  def wildcard_match?(search_str, value)
    if search_str.nil?
      return true
    end

    search_str.strip!
    if search_str == ""
      return true
    end

    if !(search_str =~ /\*/)
      search_str = "*" + search_str + "*"
    end

    # make the regexp safe
    wildcard_parse = search_str.split('*')
    wildcard_re = ""
    for element in wildcard_parse
      if element == ""
        wildcard_re += ".*"
      else
        wildcard_re += Regexp.escape(element)
      end
    end

    # check for wildcard as last char
    if search_str.ends_with? '*'
      wildcard_re += ".*"
    end

    wildcard_re = "^" + wildcard_re + "$"
    if /#{wildcard_re}/.match(value)
      return true
    else
      return false
    end
  end

  def index
    @userinfo = ExpressUserinfo.new :rhlogin => session[:login],
                                    :ticket => session[:ticket]
    @userinfo.establish
    @app = ExpressApp.new

    @app_type_filter_value = ""
    @name_filter_value = ""

    if !params.nil?
      @app_type_filter_value = params[:app_type_filter]
      @name_filter_value = params[:name_filter]
    end

    @app_type_options = [["All", ""]]
    seen_app_types = {}
    @filtered_app_info = {}

    if !@userinfo.app_info.nil?
      @userinfo.app_info.each do |app_name, app|
        app_type = app['framework'].split('-')[0]
        if !seen_app_types.has_key? app_type
          @app_type_options << app_type
        end
        seen_app_types[app_type] = true

        # filter
        if wildcard_match? @name_filter_value, app_name
          if @app_type_filter_value.nil? || @app_type_filter_value == ""
            @filtered_app_info[app_name] = app
          elsif @app_type_filter_value == app_type 
            @filtered_app_info[app_name] = app
          end
        end
      end
    end
    render
  end

  def confirm_delete
    @userinfo = ExpressUserinfo.new :rhlogin => session[:login],
                                    :ticket => session[:ticket]
    @userinfo.establish

    @app_name = params['app_name']
    if @app_name.nil?
      @message_type = :error
      @message = "No application specified"
    else
      @app = @userinfo.app_info[@app_name]
      if @app.nil?
        @message_type = :error
        @message = "Application " + @app_name + " does not exist"
      end
    end

    respond_to do |format|
      if @message_type == :error
        flash[@message_type] = @message
        format.html { redirect_to applications_path }
        format.js { render :json => response }
      else
        render
      end
    end
  end
end
