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

=begin
# Once legacy api support can be removed these overrides are all that are needed
raise "Code needs upgrade for unknown rails version" unless Rails.version.to_f == 3.2
class ActionDispatch::Routing::Mapper
  module Resources
    RESOURCE_OPTIONS  << :singular_resource
    class Resource
      def member_scope
        @options[:singular_resource] ? "#{singular}/:id" : "#{path}/:id"
      end

      def nested_scope
        @options[:singular_resource] ? "#{singular}/:#{singular}_id" : "#{path}/:#{singular}_id"
      end
    end
  end
end
=end

raise "Code needs upgrade for unknown rails version" unless Rails.version.to_f == 3.2
class ActionDispatch::Routing::Mapper
  module Resources
    RESOURCE_OPTIONS  << :singular_resource << :expose_legacy_api
    class Resource
      attr_accessor :expose_legacy_api
      # Override the path generation behavior
      def member_scope
        @options[:singular_resource] && !expose_legacy_api ? "#{singular}/:id" : "#{path}/:id"
      end

      def nested_scope
        @options[:singular_resource] && !expose_legacy_api ? "#{singular}/:#{singular}_id" : "#{path}/:#{singular}_id"
      end
    end
    
    def resources(*resources, &block)
      options = resources.extract_options!.dup

      # Shallow copy these arrays since the nested resource stack 
      # will be traversed twice
      resources_copy = resources.dup
      options_copy = options.dup

      # Are we currently on the path for generating the legacy routes
      expose_legacy_api_set = @scope[:expose_legacy_api]

      # If we are not currently and haven't already generated legacy routes
      # determine if we need to start generating them
      if (@scope[:expose_legacy_api].nil?)
        if (options[:singular_resource] && options[:expose_legacy_api])
          @scope[:expose_legacy_api] = true
        end
      end

      # The legacy route generation path, generates all plural paths
      if (@scope[:expose_legacy_api])
        _resources_body(resources_copy, options_copy, true, &block)
      end
      
      # The regular route generation path, if the resource has :singular_resource
      # then this is the path that will create the new singular routes
      if !expose_legacy_api_set
        if (!@scope[:expose_legacy_api].nil?)
          @scope[:expose_legacy_api] = false
        end
        _resources_body(resources, options, false, &block)
      end

      self
    end

    def _resources_body(resources, options, expose_legacy_api, &block)
      if apply_common_behavior_for(:resources, resources, options, &block)
        return self
      end

      @scope[:expose_legacy_api] = nil unless expose_legacy_api

      resource_scope(:resources, Resource.new(resources.pop, options)) do
        yield if block_given?

        # Only generate collection routes or new route if this resource doesn't
        # have :expose_legacy_api set, or if we are currently going down the
        # path of exposing the legacy apis
        collection do
          get  :index if parent_resource.actions.include?(:index)
          post :create if parent_resource.actions.include?(:create)
        end if !options[:expose_legacy_api] || expose_legacy_api

        new do
          get :new
        end if parent_resource.actions.include?(:new) && (!options[:expose_legacy_api] || expose_legacy_api)

        member do
          get    :edit if parent_resource.actions.include?(:edit)
          get    :show if parent_resource.actions.include?(:show)
          put    :update if parent_resource.actions.include?(:update)
          delete :destroy if parent_resource.actions.include?(:destroy)
        end

      end
    end

    # Overrides of member and nested were needed to pass the expose_legacy_api state
    # through to the resource object
    alias_method :orig_member, :member
    def member
      unless resource_scope?
        raise ArgumentError, "can't use member outside resource(s) scope"
      end
      parent_resource.expose_legacy_api = @scope[:expose_legacy_api]
      orig_member {yield}
      parent_resource.expose_legacy_api = nil
    end

    alias_method :orig_nested, :nested
    def nested
      unless resource_scope?
        raise ArgumentError, "can't use nested outside resource(s) scope"
      end
      parent_resource.expose_legacy_api = @scope[:expose_legacy_api]
      orig_nested {yield}
      parent_resource.expose_legacy_api = nil
    end
  end
end