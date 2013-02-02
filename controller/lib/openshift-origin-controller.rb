require "openshift-origin-common"

module OpenShift
  module Controller
    require 'controller_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3

    autoload :ApiBehavior,             'openshift/controller/api_behavior'
    autoload :ApiResponses,            'openshift/controller/api_responses'
    autoload :ActionLog,               'openshift/controller/action_log'
  end

  module Auth
  end

  autoload :ApplicationContainerProxy, 'openshift/application_container_proxy'

  autoload :AuthService,               'openshift/auth_service'
  autoload :DnsService,                'openshift/dns_service'
  autoload :DataStore,                 'openshift/data_store'
  autoload :MongoDataStore,            'openshift/mongo_data_store'

  autoload :UserActionLog,             'openshift/user_action_log'
end

require "openshift/exceptions"
