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

  def gear_sizes
    Array(capabilities[:gear_sizes]).map(&:to_sym)
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
    class_attribute :attrs
    def self.cache_attribute(*attrs)
      self.attrs ||= []
      return self.attrs if attrs.empty?
      self.attrs += attrs
      attrs.each{ |s| attr_reader s }
    end

    #
    # Raise if the values cannot be converted
    #
    def self.from(obj)
      case obj
      when Array then new(*obj)
      when Hash then  new(*attrs.map{ |s| obj[s] || obj[s.to_s] })
      else            new(*attrs.map{ |s| obj.send(s) })
      end if obj
    end

    # Changing this order will break serialization of cached data
    cache_attribute :max_gears, :consumed_gears, :gear_sizes, :plan_id

    include Helpers

    def initialize(*args)
      arg = args.each
      self.class.attrs.each{ |t| send("#{t}=", arg.next) }
    rescue StopIteration
    end

    def to_a
      self.class.attrs.map{ |s| send(s) }.map!{ |v| v == UnlimitedGears ? nil : v }
    end
    def to_session
      to_a
    end

    def gear_sizes
      Array(@gear_sizes).map(&:to_sym)
    end
    def max_gears
      @max_gears || UnlimitedGears
    end

    protected
      def max_gears=(i)
        @max_gears = i ? Integer(i) : nil
      end
      def consumed_gears=(i)
        @consumed_gears = Integer(i)
      end
      def gear_sizes=(arr)
        @gear_sizes = Array(arr)
      end
      def plan_id=(id)
        @plan_id = id.nil? ? nil : id.to_s
      end
  end
end
