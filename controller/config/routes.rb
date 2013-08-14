Rails.application.routes.draw do
  id_with_format = OpenShift::Controller::Routing::ID_WITH_FORMAT

  scope "/broker/rest" do
    resource :api, :only => :show, :controller => :api
    resource :environment, :only => [:show], :controller => :environment
    resource :user, :only => [:show, :destroy], :controller => :user do
      match 'domains' => 'domains#index', :owned => true
      resources :keys, :only => [:index, :show, :create, :update, :destroy], :controller => :keys, :constraints => { :id => id_with_format }, :singular_resource => true, :expose_legacy_api => true
      resources :authorizations, :controller => :authorizations, :constraints => { :id => id_with_format }, :only => [:index, :show, :destroy, :create, :update], :singular_resource => true, :expose_legacy_api => true
      match 'authorizations' => 'authorizations#destroy_all', :via => :delete
    end
    resources :cartridges, :only => [:index, :show], :constraints => { :id => id_with_format }, :singular_resource => true, :expose_legacy_api => true
    resources :quickstarts, :only => [:index, :show], :singular_resource => true, :expose_legacy_api => true
    resources :estimates, :constraints => { :id => id_with_format }, :only => [:index, :show], :singular_resource => true, :expose_legacy_api => true

    #applications can now be accessed without going through domain
    resources :applications, :only => [:index, :show, :create, :destroy], :constraints => { :id => id_with_format }, :singular_resource => true, :expose_legacy_api => true do
      resource :descriptor, :only => :show
      resources :gear_groups, :constraints => { :id => id_with_format }, :only => [:index, :show], :singular_resource => true
      #added back the gears URL so we can return an appropriate message instead of a routing error
      resources :gears, :only => [:index, :show], :singular_resource => true
      resources :cartridges, :controller => :emb_cart, :only => [:index, :show, :create, :update, :destroy], :constraints => { :id => id_with_format }, :singular_resource => true do
        resources :events, :controller => :emb_cart_events, :only => :create, :singular_resource => true
      end
      resources :events, :controller => :app_events, :only => :create, :singular_resource => true
      resource :dns_resolvable, :only => :show, :controller => :dns_resolvable
      resources :aliases, :only => [:index, :show, :create, :update, :destroy], :controller => :alias, :constraints => { :id => id_with_format }, :singular_resource => true
      resources :members, :only => :index, :controller => :application_members, :constraints => { :id => id_with_format }, :singular_resource => true
      #match 'members' => 'application_members#destroy_all', :via => :delete
    end
    # Allow restful update of the domain name via the standard id parameter
    # Include support for the legacy plural API pattern domains/:existing_id for now
    match "domains/:existing_id" => "domains#update", :via => :put, :existing_id => id_with_format
    match "domain/:existing_id" => "domains#update", :via => :put, :existing_id => id_with_format
    resources :domains, :only => [:index, :show, :create, :update, :destroy], :constraints => { :id => id_with_format }, :singular_resource => true, :expose_legacy_api => true do
      resources :members, :only => [:index, :create, :update, :destroy], :controller => :domain_members, :constraints => { :id => id_with_format }, :singular_resource => true
      match 'members' => 'domain_members#destroy_all', :via => :delete
      resources :applications, :controller => :applications, :only => [:index, :show, :create, :destroy], :constraints => { :id => id_with_format }, :singular_resource => true do
        resource :descriptor, :only => :show
        resources :gear_groups, :constraints => { :id => id_with_format }, :only => [:index, :show], :singular_resource => true
        #added back the gears URL so we can return an appropriate message instead of a routing error
        resources :gears, :only => [:index, :show], :singular_resource => true
        resources :cartridges, :controller => :emb_cart, :only => [:index, :show, :create, :update, :destroy], :constraints => { :id => id_with_format }, :singular_resource => true do
            resources :events, :controller => :emb_cart_events, :only => :create, :singular_resource => true
        end
        resources :events, :controller => :app_events, :only => :create, :singular_resource => true
        resource :dns_resolvable, :only => :show, :controller => :dns_resolvable
        resources :aliases, :only => [:index, :show, :create, :update, :destroy], :controller => :alias, :constraints => { :id => id_with_format }, :singular_resource => true
        resources :members, :only => :index, :controller => :application_members, :constraints => { :id => id_with_format }, :singular_resource => true
        #match 'members' => 'application_members#destroy_all', :via => :delete
      end
    end

    root as: 'rest', to: redirect{ |params, request| "#{request.script_name}/rest/api" }
  end
end
