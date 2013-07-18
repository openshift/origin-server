module AdminConsole
  class ApplicationController < ActionController::Base
    include Rescue

    layout "admin_console"

    def active_tab
      nil
    end
  end
end
