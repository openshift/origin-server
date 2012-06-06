require 'active_support/core_ext/hash/conversions'
require 'active_resource'
require 'active_resource/associations'
require 'active_resource/reflection'
require 'active_support/concern'
require 'active_model/dirty'
require 'active_resource/persistent_connection'

module ActiveResource
  module Formats
    #
    # The OpenShift REST API wraps the root resource element whi
    # to be unwrapped.
    #
    module OpenshiftJsonFormat
      extend ActiveResource::Formats::JsonFormat
      extend self

      def decode(json)
        decoded = super
        if decoded.is_a?(Hash) and decoded.has_key?('data')
          decoded = decoded['data']
        end
        if decoded.is_a?(Array)
          decoded.each { |i| i.delete 'links' }
        else
          decoded.delete 'links'
        end
        decoded
      end
    end
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
      find_or_create_resource_for(ActiveSupport::Inflector.singularize(name.to_s))
    end

    def find_or_create_resource_for(name)
      # also sanitize names with dashes
      name = name.to_s.gsub(/[^\w\:]/, '_')
      # association support
      return reflections[name.to_sym].klass if reflections.key?(name.to_sym)

      resource_name = name.to_s.camelize
      ancestors = self.class.name.split("::")
      if ancestors.size > 1
        find_resource_in_modules(resource_name, ancestors)
      else
        self.class.const_get(resource_name)
      end
    rescue NameError
      begin
        if self.class.const_defined?(resource_name)
          resource = self.class.const_get(resource_name)
        else
          resource = self.class.const_set(resource_name, Class.new(ActiveResource::Base))
        end
      rescue NameError # invalid constant name (starting by number for example)
        resource_name = 'Constant' + resource_name
        resource = self.class.const_set(resource_name, Class.new(ActiveResource::Base))
      end
      resource.prefix = self.class.prefix
      resource.site   = self.class.site
      resource
    end
end

module RestApi
  class Base < ActiveResource::Base
    include ActiveModel::Dirty

    def self.debug
      @debug = true
      yield
    ensure
      @debug = false
    end
    def self.debug?
      @debug
    end

    # Exclude the root from JSON
    self.include_root_in_json = false

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
        define_attribute_methods [from]
      end
      def calculated_attributes
        @calculated_attributes ||= {}
      end

      # Sets the number of seconds after which persistent Net::HTTP connections to the REST API should time out.
      def idle_timeout=(timeout)
        @connection = nil
        @idle_timeout = timeout
      end

      # Gets the number of seconds after which persistent Net::HTTP connections to the REST API should time out.
      def idle_timeout
        if defined?(@idle_timeout)
          @idle_timeout
        elsif superclass != Object && superclass.idle_timeout
          superclass.idle_timeout
        end
      end
    end

    def load(attributes)
      raise ArgumentError, "expected an attributes Hash, got #{attributes.inspect}" unless attributes.is_a?(Hash)
      @prefix_options, attributes = split_options(attributes)

      attributes = attributes.dup
      aliased = self.class.aliased_attributes
      calculated = self.class.calculated_attributes
      known = self.class.known_attributes

      aliased.each do |from,to|
        value = attributes.delete(from)
        send("#{to}=", value) unless value.nil?
      end

      attributes.each do |key, value|
        if !known.include? key.to_s and !calculated.include? key and respond_to?("#{key}=") 
          send("#{key}=", value)
        else
          @attributes[key.to_s] =
            case value
              when Array
                resource = find_or_create_resource_for_collection(key)
                value.map do |attrs|
                  if attrs.is_a?(Hash)
                    attrs[:as] = as if resource.method_defined? :as=
                    resource.new(attrs)
                  else
                    attrs.duplicable? ? attrs.dup : attrs
                  end
                end
              when Hash
                resource = find_or_create_resource_for(key)
                value[:as] = as if resource.method_defined? :as=
                resource.new(value)
              else
                value.dup rescue value
            end
        end
      end

      calculated.each_key { |key| send("#{key}=", attributes[key]) if attributes.include?(key) }
      self
    end

    #
    # Ensure user authorization info is duplicated
    #
    def dup
      super.tap do |resource|
        resource.as = @as
      end
    end
    def clone
      super.tap do |resource|
        resource.as = @as
      end
    end

    # Track persistence state, merged from 
    # https://github.com/railsjedi/rails/commit/9333e0de7d1b8f63b19c99d21f5f65fef0ce38c3
    #
    def initialize(attributes = {}, persisted=false)
      @persisted = persisted
      @as = attributes.delete :as
      super attributes
    end

    # changes to instantiate_record tracked below

    def new?
      !persisted?
    end

    def persisted?
      @persisted
    end

    def load_attributes_from_response(response)
      if response['Content-Length'] != "0" && response.body.strip.size > 0
        load(self.class.format.decode(response.body))
        @attributes[:messages] = ActiveSupport::JSON.decode(response.body)['messages']
        @persisted = true
        remove_instance_variable(:@update_id) if @update_id
      end
    end

    def save(*args)
      @previously_changed = changes # track changes
      valid = super
      remove_instance_variable(:@update_id) if @update_id && valid
      @changed_attributes.clear
      valid

    rescue ActiveResource::ConnectionError => error
      # if the server returns a body that has messages, filter them through
      # the error handler.  If one or more errors were set, assume that the message
      # is more useful than the exception and return false. Otherwise throw as ActiveResource
      # would
      raise unless set_remote_errors(error, true)
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

    class << self

      # ActiveResources doesn't completely support ActiveModel::Dirty
      # so implement it for mutable attributes
      def mutable_attribute(name)
        # we need to unset this so that define_attribute_methods
        # doesn't just return
        @attribute_methods_generated = false
        define_attribute_methods [:"#{name}"]
        define_method :"#{name}=" do |val|
          m = method "#{name}_will_change!"
          m.call unless val == @attributes[name]

          @attributes[name] = val
        end
      end

      def custom_id(name, mutable=false)
        raise "Name #{name.inspect} must be a symbol" unless name.is_a?(Symbol) && !name.is_a?(Class)
        @primary_key = name
        @update_id = nil
        if mutable
          # we need to unset this so that define_attribute_methods
          # doesn't just return
          @attribute_methods_generated = false
          define_attribute_methods [:"#{name}"]
          define_method :"#{name}=" do |val|
            m = method "#{name}_will_change!"
            m.call unless val == @attributes[name]
            @update_id = @attributes[name] if @update_id.nil?
            @attributes[name] = val
          end
          define_method :to_param do
            @update_id || @attributes[name]
          end
        else
          define_method :to_param do
            @attributes[name]
          end
        end
      end
    end

    #
    # singleton support as https://rails.lighthouseapp.com/projects/8994/tickets/4348-supporting-singleton-resources-in-activeresource
    #
    class << self
      def singleton
        @singleton = true
      end
      def singleton?
        @singleton if defined? @singleton
      end

      attr_accessor_with_default(:collection_name) do
        if singleton?
          element_name
        else 
          ActiveSupport::Inflector.pluralize(element_name)
        end
      end

      def element_path(id = nil, prefix_options = {}, query_options = nil) #changed
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        #"#{prefix(prefix_options)}#{collection_name}/#{URI.escape id.to_s}.#{format.extension}#{query_string(query_options)}"
        #begin changes
        path = "#{prefix(prefix_options)}#{collection_name}"
        unless singleton?
          raise ArgumentError, "id is required for non-singleton resources #{self}" if id.nil?
          path << "/#{URI.escape id.to_s}"
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
          instantiate_record(get(from, options[:params]))
        when String
          path = "#{from}#{query_string(options[:params])}"
          instantiate_record(format.decode(connection(options).get(path, headers).body), as) #changed
        when nil #begin add
          prefix_options, query_options = split_options(options[:params])
          path = element_path(nil, prefix_options, query_options)
          instantiate_record(format.decode(connection(options).get(path, headers).body), as) #end add
        end
      end
    end


    #
    # has_many / belongs_to placeholders
    #
    #class << self
    #  def has_many(sym)
    #  end
    #  def belongs_to(sym)
    #    prefix = "#{site.path}#{sym.to_s}"
    #  end
    #end

    #
    # Must provide OpenShift compatible error decoding
    #
    def load_remote_errors(remote_errors, save_cache=false, optional=false)
      case self.class.format
      when ActiveResource::Formats[:openshift_json]
        response = remote_errors.response
        begin
          ActiveSupport::JSON.decode(response.body)['messages'].each do |m|
            self.class.translate_api_error(errors, m['exit_code'], m['field'], m['text'])
          end
          Rails.logger.debug "Found errors on the response object: #{errors.inspect}"
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
      else
        super
      end
    end

    #FIXME may be refactored
    def remote_results
      (attributes[:messages] || []).select{ |m| m['field'] == 'result' }.map{ |m| m['text'].presence }.compact
    end

    class << self
      def on_exit_code(code, handles=nil, &block)
        (@exit_code_conditions ||= {})[code] = handles || block
      end
      def translate_api_error(errors, code, field, text)
        Rails.logger.debug "Server error: :#{field} \##{code}: #{text}"
        if @exit_code_conditions
          handler = @exit_code_conditions[code]
          case handler
          when Proc then return if handler.call errors, code, field, text
          when Class then raise handler, text
          end
        end
        message = I18n.t(code, :scope => [:rest_api, :errors], :default => text.to_s)
        errors.add( (field || 'base').to_sym, message) unless message.blank?
      end
    end


    #
    # Override method from CustomMethods to handle body objects
    #
    def get(custom_method_name, options = {})
      self.class.send(:instantiate_collection, self.class.format.decode(connection.get(custom_method_element_url(custom_method_name, options), self.class.headers).body), as, prefix_options ) #changed
    end

    #
    # Override methods from ActiveResource to make them contextual connection
    # aware
    #
    def reload
      self.load(self.class.find(to_param, :params => @prefix_options, :as => as).attributes)
    end

    class << self
      def get(custom_method_name, options = {}, call_options = {})
        connection(call_options).get(custom_method_collection_url(custom_method_name, options), headers)
      end
      def delete(id, options = {})
        connection(options).delete(element_path(id, options)) #changed
      end

      #
      # Make connection specific to the instance, and aware of user context
      #
      def connection(options = {}, refresh = false)
        c = if defined?(@connection) || superclass == Object || superclass == ActiveResource::Base
          @connection = update_connection(ActiveResource::PersistentConnection.new(site, format)) if refresh || @connection.nil?
          @connection
        else
          superclass.connection(options, refresh)
        end

        raise MissingAuthorizationError unless options[:as]
        UserAwareConnection.new(c, options[:as])
      end

      protected
        def find_single(scope, options)
          prefix_options, query_options = split_options(options[:params])
          path = element_path(scope, prefix_options, query_options)
          instantiate_record(format.decode(connection(options).get(path, headers).body), options[:as], prefix_options) #changed
        end

        def find_every(options)
          begin
            as = options[:as]
            case from = options[:from]
            when Symbol
              instantiate_collection(format.decode(get(from, options[:params], options).body), as) #changed
            when String
              path = "#{from}#{query_string(options[:params])}"
              instantiate_collection(format.decode(connection(options).get(path, headers).body) || [], as) #changed
            else
              prefix_options, query_options = split_options(options[:params])
              path = collection_path(prefix_options, query_options)
              instantiate_collection(format.decode(connection(options).get(path, headers).body) || [], as, prefix_options ) #changed
            end
          rescue ActiveResource::ResourceNotFound => e
            # changed to return empty array on not found
            # Swallowing ResourceNotFound exceptions and return nil - as per
            # ActiveRecord.
            [] #changed
          end
        end

      private
        def update_connection(connection)
          connection.proxy = proxy if proxy
          connection.user = user if user
          connection.password = password if password
          connection.auth_type = auth_type if auth_type
          connection.timeout = timeout if timeout
          connection.idle_timeout = idle_timeout if idle_timeout
          connection.ssl_options = ssl_options if ssl_options
          connection.connection_name = 'rest_api'
          connection
        end

        def instantiate_collection(collection, as, prefix_options = {}) #changed
          collection.collect! { |record| instantiate_record(record, as, prefix_options) } #changed
        end

        def instantiate_record(record, as, prefix_options = {}) #changed
          record[:as] = as # changed - called before new so that nested resources are created
          new(record, true).tap do |resource| #changed for persisted flag
            resource.prefix_options = prefix_options
          end
        end
    end

    def as=(as)
      @connection = nil
      @as = as
    end

    protected
      #
      # The user under whose context we will be accessing the remote server
      #
      def as
        return @as
      end

      def connection(refresh = false)
        raise "All RestApi model classes must have the 'as' attribute set in order to make remote requests" unless as
        @connection = nil if refresh
        @connection ||= self.class.connection({:as => as})
      end

      # Helper to avoid subclasses forgetting to set @remote_errors
      def set_remote_errors(error, optional=false)
        @remote_errors = error
        load_remote_errors(@remote_errors, true, optional)
      end
  end
  
  #
  # An Authorization object should expose:
  #
  #  login - method returning an identifier for the user
  #
  # and one of:
  #
  #  ticket - the unique ticket for the session
  #  password - a user password
  #
  class Authorization
    attr_reader :login, :ticket, :password
    def initialize(login,ticket=nil,password=nil)
      @login = login
      @ticket = ticket
      @password = password
    end
    def cache_key
      login
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
      @user = @as.login if @as.respond_to? :login
      @password = @as.password if @as.respond_to? :password
    end

    def authorization_header(http_method, uri)
      headers = super
      if @as.respond_to? :ticket and @as.ticket
        (headers['Cookie'] ||= '') << "rh_sso=#{@as.ticket}"
      end
      headers
    end

    def http
      @connection.send(:http)
    end

    #
    # Changes made in commit https://github.com/rails/rails/commit/51f1f550dab47c6ec3dcdba7b153258e2a0feb69#activeresource/lib/active_resource/base.rb
    # make GET consistent with other verbs (return response)
    #
    def get(path, headers = {})
      with_auth { request(:get, path, build_request_headers(headers, :get, self.site.merge(path))) } #changed, remove .body at end, removed format decode
    end
  end

  # Raised when the authorization context is missing
  class MissingAuthorizationError < StandardError ; end

  # Raised when a newly created resource exists with the same unique primary key
  class ResourceExistsError < StandardError ; end

  # The server did not return the response we were expecting, possibly a server bug
  class BadServerResponseError < StandardError
  end
end

class RestApi::Base
  #
  # Connection properties
  #
  self.format = :openshift_json
  self.ssl_options = { :verify_mode => OpenSSL::SSL::VERIFY_NONE }
  self.timeout = 180
  self.idle_timeout = 10
  unless Rails.env.production?
    self.proxy = ('http://' + ENV['http_proxy']) if ENV.has_key?('http_proxy')
  end
  self.site = if defined?(Rails) && Rails.configuration.express_api_url
    Rails.configuration.express_api_url + '/broker/rest'
  else
    'http://localhost/broker/rest'
  end
end
