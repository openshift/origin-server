require 'active_support/configurable'
require 'active_support/core_ext/hash'
require 'console/config_file'

module Console

 # Configures global settings for Console
 # Console.configure do |config|
 # config.disable_assets = 10
 # end
 def self.configure(file=nil,&block)
   config.send(:load, file) if file
   yield config if block_given?
 end

 # Global settings for Console
 def self.config
   @config ||= Configuration.new
 end

 class InvalidConfiguration < StandardError ; end

 class Configuration #:nodoc:
    include ActiveSupport::Configurable

    config_accessor :disable_static_assets
    config_accessor :parent_controller
    config_accessor :security_controller
    config_accessor :passthrough_headers
    config_accessor :passthrough_user_header
    config_accessor :disable_account
    config_accessor :cartridge_type_metadata
    config_accessor :include_helpers

    Builtin = {
      :openshift => {
        :url => 'https://openshift.redhat.com/broker/rest',
        :suffix => 'rhcloud.com'
      },
      :local => {
        :url => 'https://localhost/broker/rest',
        :suffix => 'dev.rhcloud.com'
      }
    }
    Builtin.freeze

    def api=(config)
      config = case
        when Builtin[config]
          source = config
          Builtin[config]
        when config == :external
          source = '~/.openshift/console.conf'
          api_config_from(Console::ConfigFile.new(source))
        when config.respond_to?(:[])
          source = 'object in config'
          Builtin[:openshift].with_indifferent_access.merge(config)
        else
          raise InvalidConfiguration, "Invalid argument to Console.config.api #{config.inspect}"
        end

      unless config[:url]
        raise InvalidConfiguration, <<-EXCEPTION.strip_heredoc
          The console requires that Console.config.api be set to a symbol or endpoint configuration object.  Active configuration is #{Rails.env}

          '#{config.inspect}' via #{source} is not valid.

          Valid symbols: #{Builtin.each_key.collect {|k| ":#{k}"}.concat([:external]).join(', ')}
          Valid api object:
            {
              :url => '' # A URL pointing to the root of the REST API, e.g. 
                         # https://openshift.redhat.com/broker/rest
            }
        EXCEPTION
      end

      freeze_api(config, source)
    end
    def api
      @api
    end

    def cartridge_type_metadata
      @cartridge_type_metadata || File.expand_path(File.join('config', 'cartridge_types.yml'), Console::Engine.root)
    end

    protected

      def load(file)
        config = Console::ConfigFile.new(file)
        raise InvalidConfiguration, "broker_url not specified in #{file}" unless config[:broker_url]

        freeze_api(api_config_from(config), file)

        case config[:console_security]
        when 'basic'
          self.security_controller = 'Console::Auth::Basic'
        when 'passthrough'
          self.security_controller = 'Console::Auth::Passthrough'
          [:passthrough_headers, :passthrough_user_header].each do |s|
            self.send(:"#{s}=", s.to_s.ends_with?('s') ? config[s].split(',') : config[s]) if config[s]
          end
        when String
          self.security_controller = config[:console_security]
        end
      end

      def to_ruby_value(s)
        case
        when s == nil
          nil
        when s[0] == '{'
          eval(s)
        when s[0] == ':'
          s[1..-1].to_sym
        when s =~ /^\d+$/
          s.to_i
        else
          s
        end
      end

      def api_config_from(config)
        config.inject(HashWithIndifferentAccess.new) do |h, (k, v)|
          if match = /^broker_api_(.*)/.match(k)
            h[match[1]] = to_ruby_value(v)
          end
          h
        end.merge({
          :url    => config[:broker_url],
          :proxy  => config[:broker_proxy_url],
          :suffix => config[:domain_suffix],
        })
      end

      def freeze_api(config, source)
        @api = {
          :user_agent => "openshift_console/#{Console::VERSION::STRING} (ruby #{RUBY_VERSION}; #{RUBY_PLATFORM})"
        }.with_indifferent_access.merge(config)
        @api[:source] = source
        @api.freeze
      end
  end

  configure do |config|
    config.disable_static_assets = false
    config.disable_account = false
    config.parent_controller = 'ApplicationController'
    config.security_controller = 'Console::Auth::Passthrough'
    config.include_helpers = true
  end
end
