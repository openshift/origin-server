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

    begin
      url = URI.parse('https://streamline.devlab.phx1.redhat.com/wapps/streamline/registration.html')
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data({ 'emailAddress' => @user.emailAddress,  
                          'password' => @user.password, 
                          'passwordConfirmation' => @user.passwordConfirmation,
                          'secretKey' => 'c0ldW1n3',
                          'termsAccepted' => 'true'})
      response = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
      case response
      when Net::HTTPSuccess, Net::HTTPRedirection
        if debug
          puts "HTTP response from server is:"
          json_resp.each do |k,v|
              puts "#{k.to_s}: #{v.to_s}"
          end
        end
        puts "Creation successful"
      else
        response.error!
        puts "Problem with server. Response code was #{response.code}"
        puts "HTTP response from server is #{response.body}"
        json_resp.each do |k,v|
          puts "#{k.to_s}: #{v.to_s}"
        end
      end

    rescue Net::HTTPBadResponse => e
      puts e
    end
  end
end
