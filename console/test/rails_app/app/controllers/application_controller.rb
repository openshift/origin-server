class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from 'ActiveResource::ConnectionError' do |e|
    if defined? e.response and defined? env and env
      env['broker.response'] = e.response.inspect
      env['broker.response.body'] = e.response.body if defined? e.response.body
    end
    raise e
  end
end
