Broker::Application.configure do                                                  
  config.gearchanger = {                                                          
    :rpc_options => {                                                             
     :disctimeout => 5,                                                           
     :timeout => 60,                                                              
     :verbose => false,                                                           
     :progress_bar => false,                                                      
     :filter => {"identity" => [], "fact" => [], "agent" => [], "cf_class" => []},
     :config => "/etc/mcollective/client.cfg"                                     
    },                                                                            
    :districts => {                                                               
        :enabled => false,                                                        
        :require_for_app_create => false,                                         
        :max_capacity => 6000, #Only used by district create                      
        :first_uid => 1000
      },                            
    :node_profile_enabled => false
  }                               
end