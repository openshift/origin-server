require 'console/version.rb'
require 'console/engine.rb'

module Console
  class AccessDenied < StandardError ; end
  class ApiNotAvailable < StandardError ; end
end
