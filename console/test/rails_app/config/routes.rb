Rails.application.routes.draw do
  openshift_console
  root :to => 'console_index#index'
end
