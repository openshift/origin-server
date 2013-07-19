#
# Patch Mongoid::Errors::DocumentNotFound to preserve unmatched ids so that we can display them in
# API error responses.
#

raise "Verify Mongoid::Errors::DocumentNotFound is unchanged" if Mongoid::VERSION.to_f >= 3.2

Mongoid::Errors::DocumentNotFound #force load
module Mongoid
  module Errors
    class DocumentNotFound
      #
      # Provide access to the unmatched ids if they are specified.
      # May be an empty Array.
      #
      attr_reader :unmatched
      alias_method :base_initialize, :initialize
      def initialize(klass, params, unmatched = nil)
        @unmatched = Array(unmatched)
        base_initialize(klass, params, unmatched)
      end
    end
  end
end