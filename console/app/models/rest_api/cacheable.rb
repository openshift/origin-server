#
# Inspired by Seamus Abshere cache_method, no code reuse
# https://github.com/seamusabshere/cache_method
#
# Invoke cache_method <symbol for method name>, <key string, array, or lambda> for any static method on this class
#
module RestApi
  module Cacheable
    extend ActiveSupport::Concern

    module ClassMethods
      #
      # Return an equivalent to this class that will may cache the defined results
      #
      def cached
        @cacheable ||= define_subclass
      end

      protected
        def cache_options
          @cache_opts ||= {:expires_in => 5.minutes}
        end
        def caches
          @caches ||= {}
        end
        def default_cache_timeout(time)
          cache_options[:expires_in] = time
        end
        def cache_method(method, *args)
          opts = args.extract_options!
          caches[method.to_sym] = opts
          opts[:cache_key] = args.length == 1 ? args.first : args if args.present?
        end
        def cache_find_method(symbol, key=[name, "find_#{symbol}"], opts={})
          cache_method "find_#{symbol}", key, opts.reverse_merge!(:before => remove_authorization_from_model)
        end
        def remove_authorization_from_model
          lambda { |e| Array(e).each { |c| c.as = nil } }
        end

      private
        def define_subclass
          parent = self
          parent.parent.const_set("#{parent.name.demodulize}Cached", Class.new(self) do
            #FIXME: prone to breaks, needs to be cleaner
            self.element_name = parent.element_name
            @caches = parent.caches

            def self.new(*args)
              superclass.new(*args)
            end

            def self.cached
              self
            end
            def self.name
              superclass.name
            end
            def to_partial_path
              self.class.superclass._to_partial_path
            end
            def self.cache_key_for(method, *args)
              opts = @caches[method]
              raise "Method #{method} is not cacheable #{caches.inspect}" unless opts
              key = opts[:cache_key] || [self.name, method, *args]
              key = key.call(*args) if key.is_a? Proc
              key.map! { |k| k.respond_to?(:cache_key) ? k.cache_key : k } if key.is_a? Array
              key
            end

            eigenclass = (class << self; self; end)
            caches.each_pair do |m, opts|
              name = "#{m}_without_caching".to_sym
              (opts ||= {}).merge!(parent.cache_options)

              eigenclass.class_eval do
                alias_method name, m
                define_method m do |*args, &blk|
                  key = cache_key_for(m, *args)
                  result = begin
                    Rails.cache.fetch(key, opts) do
                      send(name, *args, &blk).tap do |result|
                        opts[:before].call(result) if opts[:before]
                      end
                    end
                  rescue ArgumentError, TypeError => e
                    Rails.logger.warn e
                    parent.send(m, *args, &blk)
                  end
                  opts[:after].call(result) if opts[:after]
                  result
                end
              end
            end
          end)
        end
    end
  end
end
