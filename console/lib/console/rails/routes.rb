module ActionDispatch::Routing
  class Mapper

    def openshift_console(*args)
      opts = args.extract_options!
      openshift_console_routes
      openshift_account_routes unless (Array(opts[:skip]).include? :account || Console.config.disable_account)
      root :to => 'console_index#index', :via => :get, :as => :console
    end

    protected

      def openshift_console_routes
        id_regex = /[^\/]+/
        match 'help' => 'console_index#help', :via => :get, :as => 'console_help'
        match 'unauthorized' => 'console_index#unauthorized', :via => :get, :as => 'unauthorized'
        match 'server_unavailable' => 'console_index#server_unavailable', :via => :get, :as => 'server_unavailable'

        # Legacy plural paths
        match 'application_types/:id'=> 'application_types#show', :id => id_regex, :via => :get, :as => 'legacy_application_type'
        match 'applications/:id'=> 'applications#show', :id => id_regex, :via => :get, :as => 'legacy_application'
        match 'applications/:application_id/aliases/:id' => 'aliases#show', :application_id => id_regex, :id => id_regex, :via => :get, :as => 'legacy_application_alias'

        # Application specific resources
        resources :application_types, :only => [:show, :index], :id => id_regex, :singular_resource => true
        resources :applications, :singular_resource => true do
          resources :cartridges, :only => [:show, :create, :index], :id => id_regex, :singular_resource => true
          resources :aliases, :only => [:edit, :create, :new, :destroy, :update], :id => id_regex, :singular_resource => true do
            get :delete
          end
          resources :cartridge_types, :only => [:show, :index], :id => id_regex, :singular_resource => true
          resource :restart, :only => [:show, :update], :id => id_regex

          resource :building, :controller => :building, :id => id_regex, :only => [:show, :new, :destroy, :create] do
            get :delete
          end

          resource :scaling, :controller => :scaling, :only => [:show, :new] do
            get :delete
            resources :cartridges, :controller => :scaling, :only => :update, :id => id_regex, :singular_resource => true, :format => false #, :format => /json|csv|xml|yaml/
          end

          resource :storage, :controller => :storage, :only => :show do
            resources :cartridges, :controller => :storage, :only => :update, :id => id_regex, :singular_resource => true, :format => false #, :format => /json|csv|xml|yaml/
          end

          member do
            get :delete
            get :get_started
          end
        end
        resource :settings, :only => :show

        resources :domains, :id => id_regex, :only => [:new, :create, :edit, :update, :index, :show], :singular_resource => true
        resources :keys, :id => id_regex, :only => [:new, :create, :destroy], :singular_resource => true

        resources :authorizations, :id => id_regex, :except => :index, :singular_resource => true
        match 'authorizations' => 'authorizations#destroy_all', :via => :delete
      end

      def openshift_account_routes
        # Account specific resources
        resource :account,
                 :controller => :account,
                 :only => :show
      end
  end
end
