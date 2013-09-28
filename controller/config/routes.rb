Rails.application.routes.draw do
  id_with_format = OpenShift::Controller::Routing::ID_WITH_FORMAT

  scope "/broker/rest" do
    #
    # Singular member routes
    #
    scope singular_resource: true do
      resource :api, :only => :show, :controller => :api
      resource :environment, :only => [:show], :controller => :environment

      resources :cartridges, :only => [:index, :show], :id => id_with_format
      resources :quickstarts, :only => [:index, :show]
      resources :estimates, :id => id_with_format, :only => [:index, :show]

      resource :user, :only => [:show, :destroy], :controller => :user do
        match 'domains' => 'domains#index', :owned => true
        resources :keys, :only => [:index, :show, :create, :update, :destroy], :controller => :keys, :id => id_with_format
        resources :authorizations, :controller => :authorizations, :id => id_with_format, :only => [:index, :show, :destroy, :create, :update]
        match 'authorizations' => 'authorizations#destroy_all', :via => :delete
      end

      resources :applications, :only => [:index, :show, :create, :destroy], :id => id_with_format do
        resource :descriptor, :only => :show
        resources :gear_groups, :id => id_with_format, :only => [:index, :show]
        resources :gears, :only => [:index, :show], :id => id_with_format
        resources :cartridges, :controller => :emb_cart, :only => [:index, :show, :create, :update, :destroy], :id => id_with_format do
          resources :events, :controller => :emb_cart_events, :only => :create
        end
        resources :events, :controller => :app_events, :only => :create
        resource :dns_resolvable, :only => :show, :controller => :dns_resolvable
        resources :aliases, :only => [:index, :show, :create, :update, :destroy], :controller => :alias, :id => id_with_format
        resources :members, :only => :index, :controller => :application_members, :id => id_with_format
        resources :environment_variables, :only => [:index, :show, :create, :update, :destroy], :id => id_with_format, :path => 'environment-variables'
      end

      # Allow restful update of the domain name via the standard id parameter
      match "domain/:existing_id" => "domains#update", :via => :put, :existing_id => id_with_format

      resources :domains, :only => [:index, :show, :create, :update, :destroy], :id => id_with_format do
        resources :members, :only => [:index, :create, :update, :destroy], :controller => :domain_members, :id => id_with_format
        match 'members' => 'domain_members#create', :via => :patch
        match 'members' => 'domain_members#destroy_all', :via => :delete
        match 'members/self' => 'domain_members#leave', :via => :delete
        resources :applications, :controller => :applications, :only => [:index, :show, :create, :destroy], :id => id_with_format do
          resource :descriptor, :only => :show
          resources :gear_groups, :id => id_with_format, :only => [:index, :show]
          resources :gears, :only => [:index, :show]
          resources :cartridges, :controller => :emb_cart, :only => [:index, :show, :create, :update, :destroy], :id => id_with_format do
              resources :events, :controller => :emb_cart_events, :only => :create
          end
          resources :events, :controller => :app_events, :only => :create
          resource :dns_resolvable, :only => :show, :controller => :dns_resolvable
          resources :aliases, :only => [:index, :show, :create, :update, :destroy], :controller => :alias, :id => id_with_format
          resources :members, :only => :index, :controller => :application_members, :id => id_with_format
          resources :environment_variables, :only => [:index, :show, :create, :update, :destroy], :id => id_with_format, :path => 'environment-variables'
          resources :deployments, :only => [:index, :show, :create], :controller => :deployments, :id => id_with_format
        end
      end
    end

    #
    # DEPRECATED - Plural member resources, will be removed when API 1.1 is removed.
    #              New APIs should NOT add plural member paths.
    #
    resources :cartridges,   :only => [:show], :id => id_with_format
    resources :quickstarts,  :only => [:show]
    resources :estimates,    :only => [:show], :id => id_with_format
    scope '/user' do
      resources :keys, :only => [:show, :update, :destroy], :id => id_with_format
      resources :authorizations, :only => [:show, :destroy, :update], :id => id_with_format
    end
    resources :applications, :only => [:show, :destroy], :id => id_with_format do
      resources :gear_groups, :only => [:show], :id => id_with_format
      resources :gears, :only => [:show], :id => id_with_format
      resources :cartridges, :controller => :emb_cart, :only => [:show, :update, :destroy], :id => id_with_format
      resource  :dns_resolvable, :only => :show, :controller => :dns_resolvable
      resources :aliases, :only => [:show, :update, :destroy], :controller => :alias, :id => id_with_format
    end
    match "domains/:existing_id" => "domains#update", :via => :put, :existing_id => id_with_format
    resources :domains, :only => [:show, :update, :destroy], :id => id_with_format do
      resources :applications, :only => [:index, :show, :create, :destroy], :id => id_with_format do
        resource :descriptor, :only => :show
        resources :gear_groups, :only => [:index, :show], :id => id_with_format
        resources :gears, :only => [:index, :show]
        resources :cartridges, :controller => :emb_cart, :only => [:index, :show, :create, :update, :destroy], :id => id_with_format do
          resources :events, :controller => :emb_cart_events, :only => :create
        end
        resources :events, :controller => :app_events, :only => :create
        resource :dns_resolvable, :only => :show, :controller => :dns_resolvable
        resources :aliases, :only => [:index, :show, :create, :update, :destroy], :controller => :alias, :id => id_with_format
      end
    end

    root as: 'rest', to: redirect{ |params, request| "#{request.script_name}/rest/api" }
  end
end
