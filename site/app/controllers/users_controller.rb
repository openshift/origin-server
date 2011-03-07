require 'pp'

class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    unless @user.valid?
      render :new
    end

    # Otherwise call out to IT's service to register
    # Map any errors into the user.errors object
  end
end
