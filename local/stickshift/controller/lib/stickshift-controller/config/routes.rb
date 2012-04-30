Rails.application.routes.draw do
  match 'cartridge'       => 'legacy_broker#cartridge_post', :via => [:post]
  match 'embed_cartridge' => 'legacy_broker#embed_cartridge_post', :via => [:post]
  match 'domain'          => 'legacy_broker#domain_post', :via => [:post]
  match 'userinfo'        => 'legacy_broker#user_info_post', :via => [:post]
  match 'cartlist'        => 'legacy_broker#cart_list_post', :via => [:post]
  match 'ssh_keys'        => 'legacy_broker#ssh_keys_post', :via => [:post]    
  scope "/rest" do
    resource :api, :only => [:show], :controller => :base
    resource :user, :only => [:show], :controller => :user do
      resources :keys, :controller => :keys, :constraints => { :id => /[\w]+/ } 
    end
    resources :cartridges, :only => [:index, :show], :constraints => { :id => /standalone|embedded/ }
    resources :application_template
    resources :estimates, :constraints => { :id => /[\w]+/ }, :only => [:index, :show]

    # Allow restful update of the domain name via the standard id parameter
    match "domains/:existing_id" => "domains#update", :via => :put, :existing_id => /[A-Za-z0-9]+/
    resources :domains, :constraints => { :id => /[A-Za-z0-9]+/ } do
      resources :applications, :constraints => { :id => /[\w]+/ } do
        resource :descriptor, :only => [:show]
        resource :gears, :only => [:show]
        resources :cartridges, :controller => :emb_cart, :only => [:index, :show, :create, :destroy], :constraints => { :id => /[\w\-\.]+/ } do
            resources :events, :controller => :emb_cart_events, :only => [:create]
        end
        resources :events, :controller => :app_events, :only => [:create]
      end
    end
  end
end
