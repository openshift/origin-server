require ::File.expand_path('../test/dummy/config/environment',  __FILE__)

map '/' do
  run Dummy::Application
end
