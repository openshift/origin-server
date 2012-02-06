require 'net/http'
require 'uri'
require 'cgi'

class ExpressAppController < ApplicationController
  before_filter :require_login

  @@max_tries = 5000

  def index
    @userinfo = ExpressUserinfo.new :rhlogin => session[:login],
                                    :ticket => session[:ticket]
    @userinfo.establish
    @app = ExpressApp.new

    render
  end
end
