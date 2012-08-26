require ::File.expand_path('../test/rails_app/config/environment',  __FILE__)

map '/' do
  run RailsApp::Application
end
