module OpenShift
  module Runtime
    module Utils
      def self.sanitize_credentials(arg)
        arg.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
           .gsub(/(passwo?r?d\s*[:=]+\s*)\S+/i, '\\1[HIDDEN]')
           .gsub(/(usern?a?m?e?\s*[:=]+\s*)\S+/i,'\\1[HIDDEN]')
      end
    end
  end
end
