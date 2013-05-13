module OpenShift
  module Controller
    module Routing
      ID_WITH_FORMAT = /[^\/]+(?=\.xml\z|\.json\z|\.yml\z|\.yaml\z|\.xhtml\z)|[^\/]+/
      APP_ENV_FORMAT = /[^\/]+[A-Z0-9][A-Z0-9_]*(?=\.xml\z|\.json\z|\.yml\z|\.yaml\z|\.xhtml\z)*/
    end
  end
end