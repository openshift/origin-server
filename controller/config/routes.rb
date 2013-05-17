Rails.application.routes.draw do
  id_with_format = OpenShift::Controller::Routing::ID_WITH_FORMAT 
  
  scope "/rest" do
    resource :api, :only => :show, :controller => :api
    resource :environment, :only => [:show], :controller => :environment
    resource :user, :only => [:show, :destroy], :controller => :user do
      resources :keys, :only => [:index, :show, :create, :update, :destroy], :controller => :keys, :constraints => { :id => id_with_format }
      resources :authorizations, :controller => :authorizations, :constraints => { :id => id_with_format }, :only => [:index, :show, :destroy, :create, :update]
      match 'authorizations' => 'authorizations#destroy_all', :via => :delete
    end
    resources :cartridges, :only => [:index, :show], :constraints => { :id => id_with_format }
    resources :quickstarts, :only => [:index, :show]
    resources :estimates, :constraints => { :id => id_with_format }, :only => [:index, :show]

    # Allow restful update of the domain name via the standard id parameter
    match "domains/:existing_id" => "domains#update", :via => :put, :existing_id => id_with_format
    resources :domains, :only => [:index, :show, :create, :update, :destroy], :constraints => { :id => id_with_format } do
      resources :applications, :only => [:index, :show, :create, :destroy], :constraints => { :id => id_with_format } do
        resource :descriptor, :only => :show
        resources :gear_groups, :constraints => { :id => id_with_format }, :only => [:index, :show]
        #added back the gears URL so we can return an appropriate message instead of a routing error
        resources :gears, :only => [:index, :show]
        resources :cartridges, :controller => :emb_cart, :only => [:index, :show, :create, :update, :destroy], :constraints => { :id => id_with_format } do
            resources :events, :controller => :emb_cart_events, :only => :create
        end
        resources :events, :controller => :app_events, :only => :create
        resource :dns_resolvable, :only => :show, :controller => :dns_resolvable
        resources :aliases, :only => [:index, :show, :create, :update, :destroy], :controller => :alias, :constraints => { :id => id_with_format }
      end
    end
    root as: 'rest', to: redirect{ |params, request| "#{request.script_name}/rest/api" }
  end
end
