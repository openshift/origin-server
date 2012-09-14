require 'active_support/core_ext/hash/conversions'
require 'active_resource'
require 'active_resource/associations'
require 'active_resource/reflection'
require 'active_support/concern'
require 'active_model/dirty'
require 'active_resource/persistent_connection'

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
      if decoded.is_a?(Array)
        decoded.each{ |i| i.delete 'links'; i.merge!(attrs) if attrs }
      else
        decoded.delete 'links'
        decoded.merge!(attrs) if attrs
      end
      decoded
    end

    def root_attributes(hash)
      hash.slice('messages', *@root_attrs)
    end
  end

  class Base < ActiveResource::Base
    include ActiveModel::Dirty
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
    def clone
      super.tap do |resource|
        resource.as = @as
      end
    end

    def initialize(attributes = {}, persisted=false)
      @as = attributes.delete :as
      super attributes, persisted
    end

    def load(attributes, remove_root=false)
      raise ArgumentError, "expected an attributes Hash, got #{attributes.inspect}" unless attributes.is_a?(Hash)
      self.prefix_options, attributes = split_options(attributes)

      attributes = attributes.dup
      aliased = self.class.aliased_attributes
      calculated = self.class.calculated_attributes
      known = self.class.known_attributes

      aliased.each do |from,to|
        value = attributes.delete(from)
        send("#{to}=", value) unless value.nil?
      end

      attributes.each do |key, value|
        #Rails.logger.debug "Found nil key when deserializing #{attributes.inspect}" if key.nil?
        if !known.include? key.to_s and !calculated.include? key and respond_to?("#{key}=") 
          send("#{key}=", value)
        else
          self.attributes[key.to_s] =
            case value
              when Array
                resource = nil
                value.map do |attrs|
                  if attrs.is_a?(Hash)
                    resource ||= find_or_create_resource_for_collection(key)
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
                value.duplicable? ? value.dup : value
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

    def save_with_change_tracking(*args, &block)
      save_without_change_tracking(*args, &block).tap do |valid|
        if valid
          @previously_changed = changes
          @changed_attributes.clear
        end
      end

    rescue ActiveResource::ConnectionError => error
      # if the server returns a body that has messages, filter them through
      # the error handler.  If one or more errors were set, assume that the message
      # is more useful than the exception and return false. Otherwise throw as ActiveResource
      # would
      raise unless set_remote_errors(error, true)
    end
    alias_method_chain :save, :change_tracking

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

    class << self
      def allow_anonymous
        @allow_anonymous = true
      end
      def allow_anonymous?
        @allow_anonymous
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
      rescue ActiveResource::ResourceNotFound => e
        raise ResourceNotFound.new(self.model_name, nil, e)
      end

      def allow_anonymous?
        self.anonymous_api?
      end
      def singleton?
        self.singleton_api?
      end

      protected
        def allow_anonymous
          self.anonymous_api = true
        end
        def singleton
          self.singleton_api = true
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
      when OpenshiftJsonFormat
        response = remote_errors.response
        begin
          ActiveSupport::JSON.decode(response.body)['messages'].each do |m|
            self.class.translate_api_error(errors, (m['exit_code'].to_i rescue m['exit_code']), m['field'], m['text'])
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

    class AttributeHash < Hash
      def initialize(hash)
        hash.each_pair{ |k,v| self[k] = v }
      end
    end
    has_many :messages, :class_name => 'rest_api/base/attribute_hash'

    #FIXME may be refactored
    def remote_results
      (attributes[:messages] || []).select{ |m| m['field'] == 'result' }.map{ |m| m['text'].presence }.compact
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
      def translate_api_error(errors, code, field, text)
        Rails.logger.debug "  Server error: :#{field} \##{code}: #{text}"
        if @exit_code_conditions
          handler = @exit_code_conditions[code]
          handler = handler[:raise] if Hash === handler
          case handler
          when Proc then return if handler.call errors, code, field, text
          when Class then raise handler, text
          end
        end
        message = I18n.t(code, :scope => [:rest_api, :errors], :default => text.to_s)
        field = (field || 'base').to_sym
        errors.add(field, message) unless message.blank?

        codes = errors.instance_variable_get(:@codes)
        codes = errors.instance_variable_set(:@codes, {}) unless codes
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
          instantiate_record(format.decode(connection(options).get(path, headers).body), options[:as], prefix_options) #changed
        rescue ActiveResource::ResourceNotFound => e
          raise ResourceNotFound.new(self.model_name, scope, e)
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
          [:timeout, :idle_timeout, :read_timeout, :open_timeout].each do |sym|
            connection.send(:"#{sym}=", send(sym)) if send(sym)
          end
          connection.ssl_options = ssl_options if ssl_options
          connection.connection_name = 'rest_api'
          connection.debug_output = $stderr if RestApi.debug?
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

    protected
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

      # supports presence of AttributeMethods and Dirty
      def attribute(s)
        #puts "attribute[#{s}] #{caller.join("  \n")}"
        attributes[s]
      end

      def method_missing(method_symbol, *arguments) #:nodoc:
        #puts "in method missing of RestApi::Base #{method_symbol}"
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
          return nil if known_attributes.include?(method_name)
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
  end

  class Base
    self.idle_timeout = 4
    self.open_timeout = 3
    self.read_timeout = 180

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

      if config[:http_proxy]
        self.proxy = config[:http_proxy]
      elsif not Rails.env.production?
        self.proxy = ('http://' + ENV['http_proxy']) if ENV.has_key?('http_proxy')
      end

      @last_config = config
      @info = false
    end
  end
end

RestApi::Base.configuration = Console.config.api
