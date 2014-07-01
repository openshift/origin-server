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

    # Parses a whitespace-separated string with |-separated elements to a hash.
    # So e.g.:
    # first|http://first-url/ second|git://second-url/ =>
    # {"first"=>"http://first-url/", "second"=>"git://second-url/"}
    # Nil/empty input returns empty hash. Malformed URL raises exception.
    def self.parse_url_hash(str)
      url_hash = Hash.new
      unless str.nil? || str.empty?
        broken_urls = []
        str.split(/\s+/).each do |el|
          name, url = el.split '|'
          url.nil? and broken_urls.push(%Q[#{el} defines no URL; use "empty" for an empty git template.]) and next
          begin
            url_parts = OpenShift::Git.safe_clone_spec(url, OpenShift::Git::ALLOWED_NODE_SCHEMES)
            url_parts.nil? and broken_urls.push(%Q[#{el} does not specify a valid git URL.]) and next
            url_hash[name] = url_parts.compact.join('#')
          rescue
            broken_urls.push "#{el} is invalid: #{$!}"
          end
        end
        # Rails.logger not defined yet. Best we can do is raise an error.
        broken_urls.empty? or raise %Q[Invalid git URLs are configured:\n#{broken_urls.join "\n"}]
      end
      url_hash
    end

    # Parses a whitespace-separated string of the following form:
    # <first>|<val1>,<val2>,<val3> | <second>|<val1> | <third>|<val1>,<val2>
    # into a hash of the following form:
    # { "first" => ["val1", "val2", "val3"], "second" => ["val1"], "third" => ["val1", "val2"]}
    # The hash returns an empty list when looking up an undefined key.
    # Nil/empty input returns empty hash.
    def self.parse_tokens_hash(str)
      token_hash = Hash.new([])
      unless str.nil? || str.empty?
        missing_values = []
        str.split(/\s+/).each do |el|
          name, value_str = el.split '|'
          value_str.nil? and missing_values.push(%Q[#{el} defines no value;  it will be skipped from token hash]) and next
          values = value_str.split(",")
          token_hash[name] = values
        end
        missing_values.empty? or raise %Q[Invalid token hash configured:\n#{missing_values.join "\n"}]
      end
      token_hash
    end
  end
end
