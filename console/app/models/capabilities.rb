module Capabilities
  UnlimitedGears = 1.0/0
  extend ActiveSupport::Concern

  included do
    has_one :capabilities, :class_name => 'rest_api/base/attribute_hash'
    def capabilities
      attributes[:capabilities] || {}
    end
    include Helpers
  end

  def to_capabilities
    raise "to_capabilities must be implemented"
  end

  module Helpers
    def gears_free?
      gears_free > 0
    end

    def gears_free
      [max_gears - consumed_gears, 0].max
    end
  end

  class Cacheable
    # Changing this order will break serialization of cached data
    ATTRS = [:max_gears, :consumed_gears, :gear_sizes].
            concat(Console.config.cached_capabilities).
            each{ |s| attr_reader s }

    include Helpers

    def initialize(*args)
      arg = args.each
      ATTRS.each{ |t| send("#{t}=", arg.next) }
    rescue StopIteration
    end

    def self.from(obj)
      case obj
      when Array then new(*obj)
      when Hash then  new(*ATTRS.map{ |s| obj[s] || obj[s.to_s] })
      else            new(*ATTRS.map{ |s| obj.send(s) })
      end if obj
    end

    def to_capabilities
      self
    end

    def to_a
      ATTRS.map{ |s| send(s) }.map!{ |v| v == UnlimitedGears ? nil : v }
    end

    def gear_sizes
      Array(@gear_sizes).map(&:to_sym)
    end
    def max_gears
      @max_gears || UnlimitedGears
    end

    private
      def max_gears=(i)
        @max_gears = i ? Integer(i) : nil
      end
      def consumed_gears=(i)
        @consumed_gears = Integer(i)
      end
      def gear_sizes=(arr)
        @gear_sizes = Array(arr)
      end

      Console.config.cached_capabilities.each{ |s| attr_writer s }
  end
end
