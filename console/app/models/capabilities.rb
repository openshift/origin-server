module Capabilities
  extend ActiveSupport::Concern

  included do
    has_one :capabilities, :class_name => 'rest_api/base/attribute_hash'
    include Helpers
  end

  def gear_sizes
    @gear_sizes ||= capabilities[:gear_sizes].map(&:to_sym)
  end

  def max_storage_per_gear
    @max_storage_per_gear ||= Integer(capabilities[:max_storage_per_gear]) rescue 0
  end

  def to_capabilities
    Capabilities::Cacheable.from(self)
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
    include Helpers

    # Changing this order will break serialization of cached data
    ATTRS = [:max_gears, :consumed_gears, :gear_sizes, :max_storage_per_gear].each{ |s| attr_reader s }

    def initialize(*args)
      arg = args.each
      ATTRS.each{ |t| send("#{t}=", arg.next) }
    rescue StopIteration
    end

    def self.from(obj)
      new(*(obj.is_a?(Array) ? obj : ATTRS.map{ |s| obj.send(s) })) if obj
    end

    def to_capabilities
      self
    end

    def to_a
      ATTRS.map{ |s| send(s) }
    end

    private
      def max_gears=(i)
        @max_gears = Integer(i)
      end
      def consumed_gears=(i)
        @consumed_gears = Integer(i)
      end
      def gear_sizes=(arr)
        @gear_sizes = Array(arr)
      end
      def max_storage_per_gear=(i)
        @max_storage_per_gear = Integer(i) rescue 0
      end
  end
end
