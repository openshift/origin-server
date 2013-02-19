Rails.application.routes.draw do
  scope "/rest" do
    resource :api, :only => :show, :controller => :api
    resource :environment, :only => [:show], :controller => :environment
    resource :user, :only => [:show, :destroy], :controller => :user do
      resources :keys, :controller => :keys, :constraints => { :id => /[\w\.\-@+]+?(?=(\.(xml|json|yml|yaml|xhtml))?\z)/ }
    end
    resources :cartridges, :only => [:index, :show], :constraints => { :id => /standalone|embedded/ }
    resources :quickstarts, :only => [:index, :show]
    resources :estimates, :constraints => { :id => /[\w]+/ }, :only => [:index, :show]

    # Allow restful update of the domain name via the standard id parameter
    match "domains/:existing_id" => "domains#update", :via => :put, :existing_id => /[A-Za-z0-9]+/
    resources :domains, :constraints => { :id => /[A-Za-z0-9]+/ } do
      resources :applications, :constraints => { :id => /[\w]+/ } do
        resource :descriptor, :only => [:show]
        resources :gear_groups, :constraints => { :id => /[A-Za-z0-9]+/ }, :only => [:index, :show]
        #added back the gears URL so we can return an appropriate message instead of a routing error
        resources :gears, :only => [:index, :show]
        resources :cartridges, :controller => :emb_cart, :only => [:index, :show, :create, :update, :destroy], :constraints => { :id => /([\w\-]+(-)([\d]+(\.[\d]+)*)+)/ } do
            resources :events, :controller => :emb_cart_events, :only => [:create]
        end
        resources :events, :controller => :app_events, :only => [:create]
        resource :dns_resolvable, :only => [:show], :controller => :dns_resolvable
      end
    end
    root as: 'rest', to: redirect{ |params, request| "#{request.script_name}/rest/api" }
  end
end
