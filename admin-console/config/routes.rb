AdminConsole::Engine.routes.draw do
  id_regex = /[^\/]+/
  root :to => "index#index", :via => :get, :as => :admin_console
  post "reload", to: "index#reload"
  get "search", to: "search#index"
  resources :stats, :only => [:index, :show]
  resources :users, :only => [:show], :id => id_regex
  resources :applications, :only => [:show], :id => /.+/
  resources :gears, :only => [:show], :id => id_regex
  resources :nodes, :only => [:show], :id => id_regex
  scope "/capacity" do
    resources :profiles, :only => [:show, :index], :id => id_regex
    get "profiles/:id/nodes", to: "profiles#show_nodes", :id => id_regex, :as => "profile_nodes"
  end
  namespace :api do
    scope "/v1" do
      namespace :search do
        resources :applications, :only => [:index]
        resources :domains, :only => [:index]
        resources :districts, :only => [:index]
        resources :users, :only => [:index]
        resources :usages, :only => [:index]
      end
    end
  end
  resources :suggestions, :only => [:index]
end

# integrate admin-console routes into the broker routes.
Rails.application.routes.draw do
      mount AdminConsole::Engine => Rails.application.config.admin_console[:mount_uri]
end
