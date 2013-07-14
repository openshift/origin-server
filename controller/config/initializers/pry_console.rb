if ENV['PRY']
  OpenShift::CloudEngine.console do
    require 'pry'
    Rails::Console::IRB = Pry
    require 'rails/console/app'
    require 'rails/console/helpers'
    TOPLEVEL_BINDING.eval('self').extend ::Rails::ConsoleMethods
  end
end

