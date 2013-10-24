module OpenShift::Controller
  module Configuration
    #
    # Comma delimited list of expiration pairs, where the key corresponds
    # the canonical form of a scope, and the value corresponds to one or
    # two time durations.  The time durations may be specified in ruby and
    # are converted to seconds. The key '*' corresponds to default.
    #
    def self.parse_expiration(specs, default)
      (specs || '').split(',').inject({nil => [default.seconds]}) do |h, e|
        key, range = e.split('=').map(&:strip)
        key = nil if key == '*'
        values = range.split('|').map(&:strip).map{ |s| eval(s).seconds }
        h[key] = values
        h
      end
    end

    # Parses a comma-separated string to an array, removing extra whitespace and empty elements. Nil input returns nil. Empty input returns empty array.
    def self.parse_list(list)
      if list.nil?
        nil
      else
        list.split(',').map(&:strip).map(&:presence).compact
      end
    end
    
  end
end
