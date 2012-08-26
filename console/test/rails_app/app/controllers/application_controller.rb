class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from 'ActiveResource::ConnectionError' do |e|
    if defined? e.response and defined? env and env
      env['broker.response'] = e.response.inspect
      env['broker.response.body'] = e.response.body if defined? e.response.body
    end
    raise e
  end
  rescue_from 'ActiveResource::ResourceNotFound' do |e|
    logger.debug "#{e}\n  #{e.backtrace.join("\n  ")}"
    upgrade_in_rails_31 # FIXME: Switch to render :status => 404
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end
end
