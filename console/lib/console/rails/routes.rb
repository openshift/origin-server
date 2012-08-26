module ActionDispatch::Routing
  class Mapper

    def openshift_console(*args)
      opts = args.extract_options!
      openshift_console_routes
      openshift_account_routes unless (Array(opts[:skip]).include? :account || Console.config.disable_account)
      root :to => 'console#index', :via => :get
    end

    protected

      def openshift_console_routes
        # Help
        match 'help' => 'console#help', :via => :get, :as => 'console_help'

        # Application specific resources
        resources :application_types, :only => [:show, :index], :id => /[^\/]+/
        resources :applications do
          resources :cartridges, :only => [:show, :create, :index], :id => /[^\/]+/
          resources :cartridge_types, :only => [:show, :index], :id => /[^\/]+/

          resource :building, :controller => :building, :id => /[^\/]+/, :only => [:show, :new, :destroy, :create] do
            get :delete
          end

          resource :scaling, :controller => :scaling, :id => /[^\/]+/, :only => [:show, :new] do
            get :delete
          end

          member do
            get :delete
            get :get_started
          end
        end
      end

      def openshift_account_routes
        # Account specific resources
        resource :account,
                 :controller => :account,
                 :only => [:show]

        scope 'account' do
          resource :domain, :only => [:new, :create, :edit, :update]
          resources :keys, :only => [:new, :create, :destroy]
        end
      end
  end
end
