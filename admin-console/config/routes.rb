AdminConsole::Engine.routes.draw do
  id_regex = /[^\/]+/
  root :to => "index#index", :via => :get, :as => :admin_console
  get "search", to: "search#index"
  resources :stats, :only => [:index, :show]
  resources :users, :only => [:show], :id => id_regex
  resources :applications, :only => [:show], :id => /.+/
  resources :gears, :only => [:show], :id => id_regex
  resources :nodes, :only => [:show], :id => id_regex
  scope "/capacity" do
    resources :profiles, :only => [:show], :id => id_regex
  end
end
# integrate admin-console routes into the broker routes.
Rails.application.routes.draw do
      mount AdminConsole::Engine => Rails.application.config.admin_console[:mount_uri]
end
