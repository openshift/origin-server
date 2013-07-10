AdminConsole::Engine.routes.draw do
  id_regex = /[^\/]+/
  root :to => "index#index", :via => :get, :as => :admin_console
  get "search", to: "search#index"
  get "stats", to: "stats#index"
  resources :users, :only => [:show], :id => id_regex
  resources :applications, :only => [:show], :id => /.+/
  resources :gears, :only => [:show], :id => id_regex
  resources :nodes, :only => [:show], :id => id_regex

  scope '/rest' do
    get "stats", to: "stats#advanced"
  end
end
