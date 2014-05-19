module Capabilities
  UnlimitedGears = Float::INFINITY
  extend ActiveSupport::Concern

  included do
    has_one :capabilities, :class_name => as_indifferent_hash
    def capabilities
      attributes[:capabilities] || {}
    end
    include Helpers
  end

  def gear_sizes
    Array(capabilities[:gear_sizes]).map(&:to_sym)
  end
  alias_method :allowed_gear_sizes, :gear_sizes

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
      if obj.is_a? Array
        version = obj.first
        raise "Mismatched serialized version" if version != -serialize_version
        new(*obj[1..-1])
      elsif obj.respond_to? :[]
        new(*attrs.map{ |s| obj[s] || obj[s.to_s] })
      else
        new(*attrs.map{ |s| obj.send(s) })
      end if obj
    end

    def self.serialize_version
      1
    end
    def serialize_version
      self.class.serialize_version
    end

    # Changing this order will break serialization of cached data
    cache_attribute :max_domains, :max_gears, :consumed_gears, :gear_sizes, :plan_id, :max_teams, :view_global_teams

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
      to_a.unshift(-self.serialize_version)
    end

    def gear_sizes
      Array(@gear_sizes).map(&:to_sym)
    end
    alias_method :allowed_gear_sizes, :gear_sizes

    def max_gears
      @max_gears || UnlimitedGears
    end
    def max_domains
      @max_domains || UnlimitedGears
    end
    def max_teams
      @max_teams || 0
    end
    def view_global_teams
      @view_global_teams || false
    end

    protected
      def max_domains=(i)
        @max_domains = i ? Integer(i) : nil
      end
      def max_gears=(i)
        @max_gears = i ? Integer(i) : nil
      end
      def max_teams=(i)
        @max_teams = i ? Integer(i) : nil
      end
      def view_global_teams=(b)
        @view_global_teams = b.nil? ? nil : !!b
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
