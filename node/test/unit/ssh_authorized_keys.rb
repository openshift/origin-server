#!/usr/bin/ruby
#
# Test the SecureShell::AuthorizedKeysFile
#
#
require 'test/unit'

require 'openshift-origin-node/model/application_container_ext/ssh_authorized_keys'

#OpenShift::Runtime::ApplicationContainerExt::SecureShell::K5login
module OpenShift
  module Runtime
    class ApplicationContainer

      attr_reader :uuid, :container_dir, :container_plugin
      def initialize

      end

      def set_ro_permission(authorized_keys_file)

      end

    end

    module ApplicationContainerExt
    end

  end
end

class TestAuthorizedKeysFile < Test::Unit::TestCase

  def testCreate
    
  end

end
