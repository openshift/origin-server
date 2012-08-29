Rails.application.routes.draw do
  scope "/rest" do
    resource :api, :only => [:show], :controller => :base
    resource :user, :only => [:show], :controller => :user do
      resources :keys, :controller => :keys, :constraints => { :id => /[\w]+/ } 
    end
    resources :cartridges, :only => [:index, :show]
    resources :application_templates
  
    # Allow restful update of the domain name via the standard id parameter
    match "domains/:existing_id" => "domains#update", :via => :put, :existing_id => /[A-Za-z0-9]+/
    resources :domains, :constraints => { :id => /[A-Za-z0-9]+/ } do
      resources :applications, :constraints => { :id => /[\w]+/ } do
        resource :descriptor, :only => [:show]
        resources :gear_groups, :only => [:index]
        resources :cartridges, :controller => :app_cart, :only => [:index, :show, :create, :destroy], :constraints => { :id => /([\w\-]+(-)([\d]+(\.[\d]+)*)+)/ } do
          resources :events, :controller => :app_cart_events, :only => [:create]
        end
        resources :events, :controller => :app_events, :only => [:create]
      end
    end
  end  
  match 'cartridge'       => 'legacy_broker#cartridge_post', :via => [:post]
  match 'embed_cartridge' => 'legacy_broker#embed_cartridge_post', :via => [:post]
  match 'domain'          => 'legacy_broker#domain_post', :via => [:post]
  match 'userinfo'        => 'legacy_broker#user_info_post', :via => [:post]
  match 'cartlist'        => 'legacy_broker#cart_list_post', :via => [:post]
  match 'ssh_keys'        => 'legacy_broker#ssh_keys_post', :via => [:post]
end
