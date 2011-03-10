require 'pp'
require 'net/http'
require 'net/https'

class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])    
    if !@user.valid?
      render :new
    else
      # Otherwise call out to IT's service to register
      # Map any errors into the user.errors object
  
      begin
        url = URI.parse('https://streamline.devlab.phx1.redhat.com/wapps/streamline/registration.html')
        req = Net::HTTP::Post.new(url.path)
        
        req.set_form_data({ 'emailAddress' => @user.emailAddress,  
                            'password' => @user.password, 
                            'passwordConfirmation' => @user.passwordConfirmation,
                            'secretKey' => 'c0ldW1n3',
                            'termsAccepted' => 'true',
                            'redirectUrl' => 'http://mcpherson.redhat.com:9292'
                            })
        http = Net::HTTP.new(url.host, url.port)
        if url.scheme == "https"
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        response = http.start {|http| http.request(req)}
        case response
        when Net::HTTPSuccess
          puts "HTTP response from server is:"
          response.each do |k,v|
              puts "#{k.to_s}: #{v.to_s}"
          end
          puts response.body
        else
          puts "Problem with server. Response code was #{response.code}"
          puts "HTTP response from server is #{response.body}"
          response.error!
        end
  
      rescue Net::HTTPBadResponse => e
        puts e
        raise
      end
    end
  end
end