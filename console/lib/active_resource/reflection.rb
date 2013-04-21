#
# Reproduced from https://github.com/rails/rails/pull/230/files for ActiveResource association support.
#
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/module/deprecation'

module ActiveResource
  # = Active Resource reflection
  #
  # Associations in ActiveResource would be used to resolve nested attributes
  # in a response with correct classes.
  # Now they could be specify over Associations with the options :class_name
  module Reflection # :nodoc:
    extend ActiveSupport::Concern

    included do
      class_attribute :reflections
      self.reflections = {}
    end

    module ClassMethods
      def create_reflection(macro, name, options)
        reflection = AssociationReflection.new(macro, name, options)

        # Simple reflection based abstraction
        if (target = "#{reflection.class_name}Associations".safe_constantize)
          method_name = "when_#{macro}".to_sym
          target.send(method_name, self, options) if target.respond_to? method_name
        end

        self.reflections = self.reflections.merge(name => reflection)
        reflection
      end
    end


    class AssociationReflection

      def initialize(macro, name, options)
        @macro, @name, @options = macro, name, options
      end

      # Returns the name of the macro.
      #
      # <tt>has_many :clients</tt> returns <tt>:clients</tt>
      attr_reader :name

      # Returns the macro type.
      #
      # <tt>has_many :clients</tt> returns <tt>:has_many</tt>
      attr_reader :macro

      # Returns the hash of options used for the macro.
      #
      # <tt>has_many :clients</tt> returns +{}+
      attr_reader :options

      # Returns the class for the macro.
      #
      # <tt>has_many :clients</tt> returns the Client class
      def klass
        @klass ||= class_name.constantize
      end

      # Returns the class name for the macro.
      #
      # <tt>has_many :clients</tt> returns <tt>'Client'</tt>
      def class_name
        @class_name ||= derive_class_name
      end

      private
        def derive_class_name
          options[:class_name] ? options[:class_name].to_s : name.to_s.classify
        end
    end
  end
end
