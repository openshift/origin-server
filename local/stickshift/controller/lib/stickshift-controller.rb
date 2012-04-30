require "stickshift-common"

module StickShift
  module Controller
    require 'stickshift-controller/engine/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
end

require "stickshift-controller/app/models/application"
require "stickshift-controller/app/models/cloud_user"
require "stickshift-controller/app/models/legacy_reply"
require "stickshift-controller/app/models/legacy_request"
require "stickshift-controller/app/models/result_io"
require "stickshift-controller/lib/stickshift/application_container_proxy"
require "stickshift-controller/lib/stickshift/auth_service"
require "stickshift-controller/lib/stickshift/dns_service"
require "stickshift-controller/lib/stickshift/data_store"
require "stickshift-controller/lib/stickshift/mongo_data_store"
