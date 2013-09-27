# Overrides the default behavior of route generation to support singular resources
# by adding two symbols on the resources / resource functions
#
# :singular_resource - if true creates routes that reference a resource by id with
#     the singular resource name, which prevents id clashes on new and edit actions
#     Example:
#        resources comments :singular_resource => true
#
#     Generates the following routes:
#        GET     /comments
#        GET     /comments/new
#        POST    /comments
#        GET     /comment/:id
#        GET     /comment/:id/edit
#        PUT     /comment/:id
#        DELETE  /comment/:id
#
# :expose_legacy_api - if true and :singular_resource is true then generate the legacy non-singular routes first
#     followed by the new singular routes
#

# Once legacy api support can be removed these overrides are all that are needed
raise "Code needs upgrade for unknown rails version" unless Rails.version.to_f == 3.2
class ActionDispatch::Routing::Mapper
  class Mapping
    IGNORE_OPTIONS << :singular_resource
  end
  module Resources
    RESOURCE_OPTIONS << :singular_resource
    class Resource
      def member_scope
        @options[:singular_resource] ? "#{singular_path}/:id" : "#{path}/:id"
      end

      def nested_scope
        @options[:singular_resource] ? "#{singular_path}/:#{singular}_id" : "#{path}/:#{singular}_id"
      end

      def singular_path
        @singular_path ||= path.to_s.singularize
      end
    end

    protected
      def apply_common_behavior_for(method, resources, options, &block) #:nodoc:
        if resources.length > 1
          resources.each { |r| send(method, r, options, &block) }
          return true
        end

        if resource_scope?
          nested { send(method, resources.pop, options, &block) }
          return true
        end

        options.keys.each do |k|
          (options[:constraints] ||= {})[k] = options.delete(k) if options[k].is_a?(Regexp)
        end

        # ADDED - Add the singular scope to the options
        options[:singular_resource] = @scope[:singular_resource] if options[:singular_resource].nil?
        # END ADDED

        scope_options = options.slice!(*RESOURCE_OPTIONS)
        unless scope_options.empty?
          scope(scope_options) do
            send(method, resources.pop, options, &block)
          end
          return true
        end

        unless action_options?(options)
          options.merge!(scope_action_options) if scope_action_options?
        end

        false
      end
  end

  module Scoping
    private
      def merge_singular_resource_scope(parent, child)
        child == false ? false : (child || parent)
      end
  end
end