Rails.application.routes.draw do

  mount AdminConsole::Engine => "/admin_console"
end
