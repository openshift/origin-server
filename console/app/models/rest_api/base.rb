require 'active_support/core_ext/hash/conversions'
require 'active_resource'
require 'active_resource/associations'
require 'active_resource/reflection'
require 'active_support/concern'
require 'active_model/dirty'
require 'active_resource/persistent_connection'
require 'net/http'
require 'cgi'

module Net
  class HTTP
    def self.enable_debug!
      raise "You don't want to do this in anything but development mode!" unless Rails.env == 'development'
      class << self
        alias_method :__new__, :new
        def new(*args, &blk)
          instance = __new__(*args, &blk)
          instance.set_debug_output($stderr)
          instance
        end
      end
    end

    def self.disable_debug!
      class << self
        alias_method :new, :__new__
        remove_method :__new__
      end
    end
  end
end

class ActiveResource::Connection
  #
  # Changes made in commit https://github.com/rails/rails/commit/51f1f550dab47c6ec3dcdba7b153258e2a0feb69#activeresource/lib/active_resource/base.rb
  # make GET consistent with other verbs (return response)
  #
  def get(path, headers = {})
    with_auth { request(:get, path, build_request_headers(headers, :get, self.site.merge(path))) } #changed, remove .body at end, removed format decode
  end

  #
  # Allow integrated debugging
  #
  def new_http
    http = if @proxy
      Net::HTTP.new(@site.host, @site.port, @proxy.host, @proxy.port, @proxy.user, @proxy.password)
    else
      Net::HTTP.new(@site.host, @site.port)
    end
    Rails.logger.debug "Connecting to #{@site}"
    http.set_debug_output $stderr if RestApi.debug?
    http
  end
end

#
# ActiveResource association support
#
class ActiveResource::Base
  extend ActiveResource::Associations
  include ActiveResource::Reflection

  private
    def find_or_create_resource_for_collection(name)
      return reflections[name.to_sym].klass if reflections.key?(name.to_sym)
      nil
    end

    alias_method :original_find_or_create_resource_for, :find_or_create_resource_for
    # Tries to find a resource for a given name; if it fails, then the resource is created
    def find_or_create_resource_for(name)
      # also sanitize names with dashes
      name = name.to_s.gsub(/[^\w\:]/, '_')
      # association support
      return reflections[name.to_sym].klass if reflections.key?(name.to_sym)
      nil
    end
end

module RestApi

  #
  # The OpenShift REST API wraps the root resource element which must
  # be unwrapped.
  #
  class OpenshiftJsonFormat
    include ActiveResource::Formats::JsonFormat

    def initialize(*args)
      @root_attrs = args
    end

    def decode(json)
      decoded = ActiveSupport::JSON.decode(json)
      if decoded.is_a?(Hash) and decoded.has_key?('data')
        attrs = root_attributes(decoded)
        decoded = decoded['data'] || {}
      end
      if decoded.is_a? Array
        decoded.map!{ |obj| delink(obj, attrs) }
      else
        delink(decoded, attrs)
      end
    end

    def delink(obj, attrs)
      obj = obj.values.first if obj.is_a?(Hash) && obj.length == 1 && obj.values.first.is_a?(Hash)
      if obj.is_a? Hash
        obj.delete 'links'
        obj.merge!(attrs) if attrs
      end
      obj
    end

    def root_attributes(hash)
      hash.slice('messages', *@root_attrs)
    end

    def mime_type
      "application/json;nolinks;version=#{RestApi::API_VERSION}"
    end
  end

  class Base < ActiveResource::Base
    include ActiveModel::Dirty
    include ActiveModel::MassAssignmentSecurity
    include RestApi::Cacheable

    # Exclude the root from JSON
    self.include_root_in_json = false

    #
    # Connection properties
    #
    # Note: Only subclasses that share this format will reuse
    #   connections (allowing HTTP 1.1 persistent connections)
    #
    self.format = OpenshiftJsonFormat.new

    #
    # ActiveResource doesn't have a hierarchy for headers
    #
    class << self
      def headers
        @headers ||= begin
          (superclass != ActiveResource::Base) ? superclass.headers.dup : {}
        end
      end
    end

    class_attribute :idle_timeout, :read_timeout, :open_timeout

    #
    # ActiveResource doesn't fully support alias_attribute
    #
    class << self
      def alias_attribute(from, to)
        aliased_attributes[from] = to

        define_method :"#{from}" do
          self.send :"#{to}"
        end
        define_method :"#{from}?" do
          self.send :"#{to}?"
        end
        define_method :"#{from}=" do |val|
          self.send :"#{to}=", val
        end
      end
      def aliased_attributes
        @aliased_attributes ||= {}
      end
      def attr_alters(from, *args)
        targets = (calculated_attributes[from] ||= [])
        targets.concat(args.flatten.uniq)
        define_attribute_method from
      end
      def calculated_attributes
        @calculated_attributes ||= {}
      end
    end

    #
    # Ensure user authorization info is duplicated
    #
    def dup
      super.tap do |resource|
        resource.as = @as
      end
    end

    #
    # Ensure Fixnums and booleans can be cloned
    #
    def clone
      # Clone all attributes except the pk and any nested ARes
      cloned = Hash[attributes.reject {|k,v| k == self.class.primary_key || v.is_a?(ActiveResource::Base)}.map { |k, v| [k, v.duplicable? ? v.clone : v] }]
      # Form the new resource - bypass initialize of resource with 'new' as that will call 'load' which
      # attempts to convert hashes into member objects and arrays into collections of objects.  We want
      # the raw objects to be cloned so we bypass load by directly setting the attributes hash.
      resource = self.class.new({})
      resource.prefix_options = self.prefix_options
      resource.send :instance_variable_set, '@attributes', cloned
      resource.as = @as # not an attribute
      resource
    end

    class HashWithSimpleIndifferentAccess < Hash
      def [](s)
        super s.to_s
      end
      def []=(s, v)
        super s.to_s, v
      end
      def delete(s)
        super s.to_s
      end
    end

    def child_prefix_options
      {}
    end

    def initialize(attributes = {}, persisted=false, prefix_options=nil)
      @as = attributes.delete :as
      @attributes     = HashWithSimpleIndifferentAccess.new
      @prefix_options = prefix_options || split_options(attributes).first
      @persisted = persisted
      load(attributes)
    end

    def attribute_load_order_sort
      lambda do |key|
        if schema and schema.has_key?(key)
          [-1, key.to_s]
        elsif reflections and reflections.has_key?(key.to_sym)
          [1,  key.to_s]
        else
          [0,  key.to_s]
        end
      end
    end

    def load(attributes, remove_root=false)
      raise ArgumentError, "expected an attributes Hash, got #{attributes.inspect}" unless attributes.is_a?(Hash)
      #self.prefix_options, attributes = split_options(attributes)

      # Clear calculated messages
      self.messages = nil

      aliased = self.class.aliased_attributes
      calculated = self.class.calculated_attributes
      known = self.class.known_attributes

      aliased.each do |from,to|
        value = attributes.delete(from)
        send("#{to}=", value) unless value.nil?
      end

      attributes.keys.sort_by(&attribute_load_order_sort).each do |key|
        value = attributes[key]

        if !known.include? key.to_s and !calculated.include? key and self.class.method_defined?("#{key}=")
          send("#{key}=", value)
        else
          @attributes[key.to_s] =
            case value
              when Array
                if value.length > 0
                  if resource = find_or_create_resource_for_collection(key)
                    value.map do |attrs|
                      if attrs.is_a?(Hash)
                        attrs[:as] = as if resource.method_defined? :as=
                        if resource < RestApi::Base
                          resource.new(attrs, persisted?, child_prefix_options)
                        else
                          resource.new(attrs)
                        end
                      else
                        attrs
                      end
                    end
                  else
                    value
                  end
                else
                  value
                end
              when Hash
                if resource = find_or_create_resource_for(key)
                  value[:as] = as if resource.method_defined? :as=
                  if resource < RestApi::Base
                    resource.new(value, persisted?, child_prefix_options)
                  else
                    resource.new(value)
                  end
                else
                  value
                end
              else
                value
            end
        end
      end

      calculated.each_key { |key| send("#{key}=", attributes[key]) if attributes.include?(key) }
      @changed_attributes.clear if @changed_attributes
      self
    end

    def attributes=(attrs)
      attrs.with_indifferent_access.slice(*(
        self.class.known_attributes + 
        self.class.aliased_attributes.keys
      )).each_pair do |k,v|
        send(:"#{k}=", v)
      end
      self
    end

    def raise_on_invalid
      (errors.instance_variable_get(:@codes) || {}).values.flatten(1).compact.uniq.each do |code|
        exc = self.class.exception_for_code(code, :on_invalid)
        raise exc.new(self) if exc
      end
      raise(ActiveResource::ResourceInvalid.new(self))
    end

    def save!
      save || raise_on_invalid
    end

    def save_with_exception_handling(options={})
      save_without_exception_handling(options)

    rescue ActiveResource::ConnectionError => error
      raise if self.class.unhandled_exceptions.any?{ |c| c === error }

      # If the server returns a body that has messages, filter them through
      # the error handler.  If one or more errors were set, assume that the message
      # is more useful than the exception and return false. Special case is "server under
      # maintenance" where we raise even having messages, to be able to logout with
      # :cause => :server_unavailable. As an improvement the broker could return an exit_code
      # for us to handle on translate_api_error. Otherwise throw as ActiveResource would.
      server_unavailable = error.response.present? &&
        error.response.respond_to?(:code) &&
        error.response.code.to_i == 503

      remote_errors = set_remote_errors(error, true)

      if server_unavailable
        raise ServerUnavailable.new(error.response)
      elsif !remote_errors
        raise
      end
      false
    end
    alias_method_chain :save, :exception_handling

    def save_with_change_tracking(*args, &block)
      save_without_change_tracking(*args, &block).tap do |valid|
        if valid
          @previously_changed = changes
          @changed_attributes.clear
        end
      end
    end
    alias_method_chain :save, :change_tracking

    class << self
      def unhandled_exceptions
        [ActiveResource::UnauthorizedAccess]
      end
    end

    # Copy calculated attribute errors
    def valid?
      super.tap { |valid| duplicate_errors unless valid }
    end

    def duplicate_errors
      self.class.calculated_attributes.each_pair do |from, attrs|
        attrs.each do |to|
          (errors[to] || []).each do |error|
            errors.add(from, error) unless errors.has_key?(from) && errors[:from].include?(error)
          end
        end
      end
      self.class.aliased_attributes.each_pair do |from, to|
        (errors[to] || []).each do |error|
          errors.add(from, error) unless errors.has_key?(from) && errors[:from].include?(error)
        end
      end
    end

    # Overrides ActiveResource::Base#destroy
    def destroy_without_notifications
      response = connection.delete(element_path, self.class.headers)
      set_remote_errors(response, true) if response.code != 204
      true
    rescue ActiveResource::ResourceNotFound => e
      raise ResourceNotFound.new(self.class.model_name, id, e.response)
    rescue ActiveResource::ForbiddenAccess => error
      @remote_errors = error
      load_remote_errors(@remote_errors, true)
      false
    end

    class << self
      def custom_id(name, mutable=false)
        raise "Name #{name.inspect} must be a symbol" unless name.is_a?(Symbol) && !name.is_a?(Class)

        define_attribute_method name

        define_method :"#{name}=" do |s|
          send(:"#{name}_will_change!") if !send(:"#{name}_changed?") && attributes[name] != s
          attributes[name] = s
        end
        define_method 'to_key' do
          persisted? ? [send(:"#{name}_was") || send(name)] : nil
        end
      end
    end

    #
    # singleton support as https://rails.lighthouseapp.com/projects/8994/tickets/4348-supporting-singleton-resources-in-activeresource
    #
    class << self
      attr_accessor :collection_name
      def collection_name
        @collection_name ||= begin
          if singleton?
            element_name
          else 
            ActiveSupport::Inflector.pluralize(element_name)
          end
        end
      end

      def encode_path_component(c)
        CGI.escape(c).gsub('+', '%20') unless c.nil?
      end

      def element_path(id = nil, prefix_options = {}, query_options = nil) #changed
        check_prefix_options(prefix_options)

        prefix_options, query_options = split_options(prefix_options) if query_options.nil?

        #begin changes
        path = "#{prefix(prefix_options)}"
        if singular_resource? && !id.nil?
          path << "#{element_name}"
        else
          path << "#{collection_name}"
        end
        unless singleton?
          raise ArgumentError, "id is required for non-singleton resources #{self}" if id.nil?
          path << "/#{encode_path_component id.to_s}"
        end
        path << ".#{format.extension}#{query_string(query_options)}"
      end

      def find(*arguments)

        scope   = arguments.slice!(0)
        options = arguments.slice!(0) || {}

        scope = :one if scope.nil? && singleton? # added

        case scope
        when :all   then find_every(options)
        when :first then find_every(options).first
        when :last  then find_every(options).last
        when :one   then find_one(options)
        else             find_single(scope, options)
        end
      end

      def find_one(options)
        as = options[:as] # for user context support

        case from = options[:from]
        when Symbol
          response = connection(call_options).get(custom_method_collection_url(from, options[:params]), headers)
          hashified = format.decode(response.body)
          instantiate_record(Formats.remove_root(hashified), as, nil, response)
        when String
          path = "#{from}#{query_string(options[:params])}"
          response = connection(options).get(path, headers)
          instantiate_record(format.decode(response.body), as, nil, response) #changed
        when nil #begin add
          prefix_options, query_options = split_options(options[:params])
          path = element_path(nil, prefix_options, query_options)
          response = connection(options).get(path, headers)
          instantiate_record(format.decode(response.body), as, nil, response) #end add
        end
      rescue ActiveResource::ResourceNotFound => e
        raise ResourceNotFound.new(self.model_name, nil, e.response)
      end

      def allow_anonymous?
        self.anonymous_api?
      end
      def singleton?
        self.singleton_api?
      end
      def use_patch_on_update?
        self.use_patch_api?
      end
      def singular_resource?
        self.singular_resource_api
      end

      protected
        def allow_anonymous
          self.anonymous_api = true
        end
        def singleton
          self.singleton_api = true
        end
        def use_patch_on_update
          self.use_patch_api = true
        end
        def singular_resource
          self.singular_resource_api = true
        end
    end

    #
    # Must provide OpenShift compatible error decoding
    #
    def self.remote_errors_for(response)
      format.decode(response.body)['messages'].map do |m| 
        [(m['exit_code'].to_i rescue m['exit_code']),
          m['field'],
          m['text'],
          (Integer(m['index']) if m['index'] rescue nil),
        ]
      end rescue []
    end

    def load_remote_errors(remote_errors, save_cache=false, optional=false, indexed_items=nil, index_field=nil)
      begin
        self.class.remote_errors_for(remote_errors.response).each do |(code, field, text, index)|
          e = errors
          if index
            if indexed_items && item = indexed_items[index]
              e = item.errors
            else
              field = index_attr
            end
          end
          self.class.translate_api_error(e, code, field, text)
        end
        Rails.logger.debug "  Found errors on the response object: #{errors.to_hash.inspect}"
        duplicate_errors
      rescue ActiveResource::ConnectionError
        raise
      rescue Exception => e
        Rails.logger.warn e
        Rails.logger.warn e.backtrace
        msg = if defined? response
          Rails.logger.warn "Unable to read server response, #{response.inspect}"
          Rails.logger.warn "  Body: #{response.body.inspect}" if defined? response.body
          defined?(response.body) ? response.body.to_s : 'No response body from server'
        else
          'No response object'
        end
        raise RestApi::BadServerResponseError, msg, $@ unless optional
      end
      optional ? !errors.empty? : errors
    end

    class AttributeHash < Hash
      def initialize(hash)
        hash.each_pair{ |k,v| self[k] = v }
      end
    end
    #
    # Provides indifferent access to a backing Hash with String keys.
    #
    class IndifferentAccess < SimpleDelegator
      def [](s)
        v = __getobj__[s.to_s]
        v = __getobj__[s] if v.nil? && !(String === s)
        v
      end
      def []=(s, v)
        __getobj__[s.to_s] = v
      end
    end
    def self.as_indifferent_hash
      IndifferentAccess
    end

    class Message < Struct.new(:exit_code, :field, :severity, :text)
      def self.from_array(messages)
        Array(messages).map do |m|
          if m.is_a? Message
            m
          elsif m['text'].present?
            Message.new(
              m['exit_code'].to_i,
              m['field'],
              m['severity'],
              m['text']
            ) 
          end
        end.compact
      end

      def to_s
        text
      end
    end

    def self.messages_for(response)
      Message.from_array(format.decode(response.body)['messages']) rescue []
    end

    def messages
      @messages ||= (Message.from_array(attributes[:messages]) rescue [])
    end

    def messages=(messages)
      @messages = nil
      if messages.present?
        attributes[:messages] = messages
      else
        attributes.delete(:messages)
      end
    end

    def extract_messages(response)
      results = RestApi::Base.format.decode(response.body)
      if results.is_a? Hash
        results['messages'] || []
      elsif results.is_a? Array
        results.first['messages'] || []
      else
        []
      end
    rescue
      []
    end

    #FIXME may be refactored
    def remote_results
      (attributes[:messages] || []).select{ |m| m['severity'] == 'result' }.map{ |m| m['text'].presence }.compact
    end
    def has_exit_code?(code, opts=nil)
      codes = errors.instance_variable_get(:@codes) || {}
      if opts && opts[:on]
        (codes[opts[:on].to_sym] || []).include? code
      else
        codes.values.any?{ |c| c.include? code }
      end
    end

    class << self
      def on_exit_code(code, handles=nil, &block)
        (@exit_code_conditions ||= {})[code] = handles || block
      end
      def translate_api_error(errors, code, field, text, index=nil)
        Rails.logger.debug "  Server error: :#{field} \##{code}: #{text} #{index}"
        if @exit_code_conditions
          handler = @exit_code_conditions[code]
          handler = handler[:raise] if Hash === handler
          case handler
          when Proc then return if handler.call errors, code, field, text
          when Class then raise handler, text
          end
        end
        message = I18n.t(code, :scope => [:rest_api, :errors], :default => text.to_s)
        field = field.presence || 'base'
        errors.add(field, message) unless message.blank?

        codes = errors.instance_variable_get(:@codes)
        codes = errors.instance_variable_set(:@codes, HashWithSimpleIndifferentAccess.new) unless codes
        (codes[field] ||= []).push(code)
      end
      def exception_for_code(code, type=nil)
        if @exit_code_conditions
          handler = @exit_code_conditions[code]
          handler = handler[type] if type && Hash === handler
          handler
        end
      end
    end


    #
    # Override method from CustomMethods to handle body objects
    #
    def get(custom_method_name, options = {})
      response = connection(options).get(custom_method_element_url(custom_method_name, options), self.class.headers)
      self.class.send(:instantiate_collection, self.class.format.decode(response.body), as, prefix_options, response) #changed
    rescue ActiveResource::ResourceNotFound => e
      raise ResourceNotFound.new(self.class.model_name, id, e.response)
    end

    #
    # Define patch method
    #
    def patch(custom_method_name, options = {}, body = '')
      begin
        connection.patch(custom_method_element_url(custom_method_name, options), body, self.class.headers)
      rescue ActiveResource::ResourceNotFound => e
        raise ResourceNotFound.new(self.class.model_name, id, e.response)
      end
    end

    [:post, :delete, :put].each do |sym|
      define_method sym do |*args|
        begin
          super *args
        rescue ActiveResource::ResourceNotFound => e
          raise ResourceNotFound.new(self.class.model_name, id, e.response)
        end
      end
    end

    #
    # Override methods from ActiveResource to make them contextual connection
    # aware
    #
    def reload
      p = prefix_options || {}
      self.load(p.merge(self.class.find(to_param, :params => p, :as => as).attributes))
    end

    #
    # Override method from CustomMethods to handle singular resource paths
    #
    def custom_method_element_url(method_name, options = {})
        path = "#{self.class.prefix(prefix_options)}"
        if self.class.singular_resource?
          path << "#{self.class.element_name}"
        else
          path << "#{self.class.collection_name}"
        end
        path << "/#{id}/#{method_name}.#{self.class.format.extension}#{self.class.__send__(:query_string, options)}"
    end

    def custom_method_collection_url(method_name, options = {})
      prefix_options, query_options = split_options(options)
      path = "#{self.class.prefix(prefix_options)}"
      if self.class.singular_resource?
        path << "#{self.class.element_name}"
      else
        path << "#{self.class.collection_name}"
      end
      path << "/#{method_name}.#{self.class.format.extension}#{self.class.__send__(:query_string, options)}"
    end

    class << self
      def get(custom_method_name, options = {}, call_options = {})
        response = connection(call_options).get(custom_method_collection_url(custom_method_name, options), headers)
        hashified = format.decode(response.body)
        derooted  = Formats.remove_root(hashified)
        derooted.is_a?(Array) ? derooted.map { |e| Formats.remove_root(e) } : derooted
      rescue ActiveResource::ResourceNotFound => e
        raise ResourceNotFound.new(self.model_name, nil, e.response)
      end
      def delete(id, options = {})
        connection(options).delete(element_path(id, options)) #changed
      rescue ActiveResource::ResourceNotFound => e
        raise ResourceNotFound.new(self.model_name, id, e.response)
      end

      #
      # Make connection specific to the instance, and aware of user context
      #
      def connection(options = {}, refresh = false)
        c = shared_connection(options, refresh)
        if options[:as]
          UserAwareConnection.new(c, options[:as])
        elsif allow_anonymous?
          c
        else
          raise RestApi::MissingAuthorizationError
        end
      end

      def shared_connection(options = {}, refresh = false)
        if defined?(@connection) || _format != superclass._format || superclass == Object || superclass == ActiveResource::Base
          @connection = update_connection(ActiveResource::PersistentConnection.new(site, format)) if refresh || @connection.nil?
          @connection
        else
          superclass.shared_connection(options, refresh)
        end
      end

      protected
        def find_single(scope, options)
          prefix_options, query_options = split_options(options[:params])
          path = element_path(scope, prefix_options, query_options)
          response = connection(options).get(path, headers)
          instantiate_record(format.decode(response.body), options[:as], prefix_options, response) #changed
        rescue ActiveResource::ResourceNotFound => e
          raise ResourceNotFound.new(self.model_name, scope, e.response)
        end

        def find_every(options)
          begin
            as = options[:as]
            case from = options[:from]
            when Symbol
              response = get(from, options[:params], options)
              instantiate_collection(format.decode(response.body), as, nil, response) #changed
            when String
              path = "#{from}#{query_string(options[:params])}"
              response = connection(options).get(path, headers)
              instantiate_collection(format.decode(response.body) || [], as, nil, response) #changed
            else
              prefix_options, query_options = split_options(options[:params])
              path = collection_path(prefix_options, query_options)
              response = connection(options).get(path, headers)
              instantiate_collection(format.decode(response.body) || [], as, prefix_options, response ) #changed
            end
          rescue ActiveResource::ResourceNotFound => e
            rescue_parent_missing(e, options)
            # changed to return empty array on not found
            # Swallowing ResourceNotFound exceptions and return nil - as per
            # ActiveRecord.
            [] #changed
          end
        end

        def rescue_parent_missing(e, options)
        end

      private
        def update_connection(connection)
          connection.proxy = proxy if proxy
          connection.user = user if user
          connection.password = password if password
          connection.auth_type = auth_type if auth_type
          [:timeout, :idle_timeout, :read_timeout, :open_timeout].each do |sym|
            connection.send(:"#{sym}=", send(sym)) if send(sym)
          end
          connection.ssl_options = ssl_options if ssl_options
          connection.connection_name = 'rest_api'
          connection.debug_output = $stderr if RestApi.debug?
          connection
        end

        def instantiate_collection(collection, as, prefix_options = {}, response = nil) #changed
          collection.collect! { |record| instantiate_record(record, as, prefix_options, response) } #changed
        end

        def instantiate_record(record, as, prefix_options = {}, response = nil) #changed
          record[:as] = as # changed - called before new so that nested resources are created
          new(record, true).tap do |resource| #changed for persisted flag
            resource.prefix_options = prefix_options
            resource.load_headers(response) if resource.respond_to?(:load_headers)
          end
        end
    end

    #
    # The user under whose context we will be accessing the remote server
    #
    def as
      @as
    end
    def as=(as)
      @connection = nil
      @as = as
    end

    def to_json(options={})
      super({:root => nil}.merge(options))
    end

    #
    # Default mass assignment support
    #
    def assign_attributes(values, options = {})
      sanitize_for_mass_assignment(values, options[:as]).each do |k, v|
        send("#{k}=", v)
      end
      self
    end

    def load_headers(response)
      self.api_identity_id = response['X-OpenShift-Identity-Id']
    end

    protected
      attr_accessor :api_identity_id

      # Support patch
      def update
        connection.send(self.class.use_patch_on_update? ? :patch : :put, element_path(prefix_options), encode, self.class.headers).tap do |response|
          load_attributes_from_response(response)
        end
      end

      def load_attributes_from_response(response)
        if (response_code_allows_body?(response.code) &&
            (response['Content-Length'].nil? || response['Content-Length'] != "0") &&
            !response.body.nil? && response.body.strip.size > 0)
          p = prefix_options || {}
          load(p.merge(self.class.format.decode(response.body)), true)
          load_headers(response) if respond_to?(:load_headers)
          @persisted = true
        end
      end

      #
      # Drupal 6 doesn't correctly encode JSON, and some non-HTML content needs to be
      # decoded.
      #
      def entity_decoded(s)
        if s && (s.include?('&#') || s.include?('&quot;'))
          CGI.unescapeHTML(s)
        else
          s
        end
      end

      def connection(refresh = false)
        @connection = nil if refresh
        @connection ||= self.class.connection({:as => as})
      end

      # Helper to avoid subclasses forgetting to set @remote_errors
      def set_remote_errors(error, optional=false)
        @remote_errors = error
        load_remote_errors(@remote_errors, true, optional)
      end

      class_attribute :anonymous_api, :instance_writer => false
      class_attribute :singleton_api, :instance_writer => false
      class_attribute :use_patch_api, :instance_writer => false
      class_attribute :singular_resource_api, :instance_writer => false

      # supports presence of AttributeMethods and Dirty
      def attribute(s)
        attributes[s.to_s]
      end

      def method_missing(method_symbol, *arguments) #:nodoc:
        method_name = method_symbol.to_s

        if method_name =~ /(=|\?)$/
          case $1
          when "="
            res = :"#{method_name}_will_change!"
            send(res) if respond_to?(res) && attributes[name] != arguments.first
            attributes[$`] = arguments.first
          when "?"
            attributes[$`]
          end
        else
          return attributes[method_name] if attributes.include?(method_name)
          # not set right now but we know about it
          return nil if known_attributes.include?(method_name) || reflections.has_key?(method_symbol)
          super
        end
      end
    end

  #
  # A connection class that contains an authorization object to connect as
  #
  class UserAwareConnection < ActiveResource::PersistentConnection

    # The authorization context
    attr_reader :as

    def initialize(connection, as)
      super connection.site, connection.format
      @connection = connection
      @as = as
      unless @as.respond_to? :to_headers
        @user = @as.login if @as.respond_to? :login
        @password = @as.password if @as.respond_to? :password
      end
    end

    def authorization_header(http_method, uri)
      headers = super
      if @as.respond_to?(:remote_ip) && (ip = @as.remote_ip.presence)
        headers['X-Forwarded-For'] = ip
      end
      if @as.respond_to?(:to_headers)
        headers.merge!(@as.to_headers)
      elsif @as.respond_to?(:ticket) and @as.ticket
        (headers['Cookie'] ||= '') << "rh_sso=#{@as.ticket}"
      end
      headers
    end

    def http
      @connection.send(:http)
    end
  end

  class Base
    self.idle_timeout = 4
    self.open_timeout = 3
    self.read_timeout = 240

    #
    # Update the configuration of the Rest API.  Use instead of
    # setting static variables directly.
    #
    def self.configuration=(config)
      return if @last_config == config

      url = URI.parse(config[:url])
      path = url.path
      if path[-1..1] == '/'
        url.path = path[0..-2]
      else
        path = "#{path}/"
      end

      self.site = url.to_s
      self.prefix = path

      [:ssl_options, :idle_timeout, :read_timeout, :open_timeout].each do |sym|
        self.send(:"#{sym}=", config[sym]) if config[sym]
      end

      self.headers.delete 'User-Agent'
      self.headers['User-Agent'] = config[:user_agent] if config[:user_agent]

      self.proxy = if config[:proxy] == 'ENV'
          :ENV
        elsif config[:proxy]
          URI config[:proxy]
        end

      @last_config = config
      @info = false
    end
  end
end

RestApi::Base.configuration = Console.config.api
