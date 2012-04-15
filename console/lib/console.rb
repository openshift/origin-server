require 'console/engine.rb'
require 'console/version.rb'

module Console
  class AccessDenied < StandardError ; end
  class ApiNotAvailable < StandardError ; end
end
