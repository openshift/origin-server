require 'jquery-rails'
require 'haml'
require 'formtastic'

module AdminConsole
  class Engine < ::Rails::Engine
    isolate_namespace AdminConsole
  end
end
