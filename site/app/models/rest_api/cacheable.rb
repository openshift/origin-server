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
        class_opts = cache_options
        if @cacheable
          self
        else
          parent = self
          Class.new(self) do
            #FIXME: prone to breaks, needs to be cleaner
            self.element_name = parent.element_name
            @cacheable = true
            @cache_opts = parent.cache_options

            def self.name
              superclass.name
            end

            eigenclass = (class << self; self; end)
            class_opts[:caches].each_pair do |m, opts|
              name = "#{m}_without_caching".to_sym
              opts ||= {}
              #puts "define method #{m} #{name}"
              eigenclass.class_eval do
                define_method m do |*args, &blk|
                  key = cache_key_for(m, args)
                  result = begin
                    Rails.cache.fetch(key, class_opts.merge(opts)) do
                      parent.send(m, *args, &blk).tap do |result|
                        opts[:before].call(result) if opts[:before]
                      end
                    end
                  rescue TypeError => e
                    Rails.logger.warn e
                    parent.send(m, *args, &blk)
                  end
                  opts[:after].call(result) if opts[:after]
                  result
                end
              end
            end
          end
        end
      end

      protected
        def cache_options
          @cache_opts ||= {:expires_in => 5.minutes, :caches => {}}
        end
        def default_cache_timeout(time)
          cache_options[:expires_in] = time
        end
        def cache_method(method, *args)
          opts = args.extract_options!
          cache_options[:caches][method.to_sym] = opts
          opts[:cache_key] = args.length == 1 ? args.first : args if args.present?
        end
        def cache_key_for(method, *args)
          opts = cache_options[:caches][method]
          raise "Method #{method} is not cacheable #{cache_options.inspect}" unless opts
          key = opts[:cache_key] || [self.superclass.name, method, *args]
          #puts "key before #{key.inspect}"
          key = key.call(*args) if key.is_a? Proc
          key.map! { |k| k.respond_to?(:cache_key) ? k.cache_key : k } if key.is_a? Array
          key
        end
    end
  end
end
