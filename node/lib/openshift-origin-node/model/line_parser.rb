module OpenShift
  module Runtime
    class LineParser
      def parse string
        valid_form = ([a-zA-Z0-9]+=[a-zA-Z0-9]+)
        matches = valid_form.match string
        matches.to_a.join("\s")
      end
    end
  end
end
