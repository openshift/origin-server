require "openshift-origin-common"

module OpenShift
  module Controller
    require 'controller_engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3

    autoload :ActionLog,               'openshift/controller/action_log'
    autoload :Authentication,          'openshift/controller/authentication'
    autoload :ApiBehavior,             'openshift/controller/api_behavior'
    autoload :ApiResponses,            'openshift/controller/api_responses'
    autoload :Configuration,           'openshift/controller/configuration'
    autoload :OAuth,                   'openshift/controller/oauth'
    autoload :ScopeAuthorization,      'openshift/controller/scope_authorization'
  end

  module Auth
    autoload :BrokerKey,               'openshift/auth/broker_key'
  end

  autoload :ApplicationContainerProxy, 'openshift/application_container_proxy'

  autoload :AuthService,               'openshift/auth_service'
  autoload :DnsService,                'openshift/dns_service'
  autoload :DataStore,                 'openshift/data_store'
  autoload :MongoDataStore,            'openshift/mongo_data_store'

  autoload :UserActionLog,             'openshift/user_action_log'
end

require "openshift/exceptions"
