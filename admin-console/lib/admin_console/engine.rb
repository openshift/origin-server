require 'rails'
require 'haml'
require 'jquery-rails'
require 'compass-rails'
require 'coffee-rails'
require 'sass-rails'
require 'uglifier'
require 'formtastic'
require 'net/http/persistent'
require 'sass/twitter/bootstrap'
require 'openshift-origin-common'
require 'openshift-origin-controller'

module AdminConsole
  class Engine < ::Rails::Engine
    isolate_namespace AdminConsole
  end
end
