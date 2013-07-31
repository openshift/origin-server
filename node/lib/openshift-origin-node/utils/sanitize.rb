module OpenShift
  module Runtime
    module Utils
      def self.sanitize_credentials(arg)
        begin
          arg.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
            .gsub(/(passwo?r?d\s*[:=]+\s*)\S+/i, '\\1[HIDDEN]')
            .gsub(/(usern?a?m?e?\s*[:=]+\s*)\S+/i,'\\1[HIDDEN]')
        rescue
          # If we were unable to encode the string, then just return it verbatim
          arg
        end
      end
      def self.sanitize_argument(arg)
        arg.to_s.gsub(/'/, '')
      end
      def self.sanitize_url_argument(url)
        url.to_s.gsub(/'/, '%27')
      end
    end
  end
end
