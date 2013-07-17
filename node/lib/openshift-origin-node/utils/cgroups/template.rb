module OpenShift
  module Runtime
    module Utils
      class Cgroups

        # Create our own hash class so we can implement comparable and change initialize
        class Template < Hash
          include Comparable

          # Allow us to pass in default values and a block
          #  - If a block is passed, it's used to create unknown values
          #  - If vals are passed, they're used to populate the Template
          #    - If the value is another Template, it copies the keys
          #    - If the value is an array, it uses those as the keys
          #    - If the value is a hash, use those values
          def initialize(*vals, &block)
            super(&block)

            case (x = vals.first)
            when Template
              values_at(*(x.keys))
            when Array
              values_at(*x)
            when Hash
              merge!(hash_to_cgroups(x))
            end

            # Coerce all values into integers if we can
            merge!(Hash[map{|k,v| [k, (Integer(v) rescue v)] }])
          end

          # Compare the values of a template
          # NOTE: It will be considered greater if *any* values are greater
          #       Or else it will then be considered less if *any* values are less
          #       Or else, it will be considered equal
          def <=>(obj)
            vals = each_pair.map do |k,v|
              v <=> obj[k]
            end
            # Find the most significant match
            [1,-1,0].find{|x| vals.include?(x) }
          end

          protected
          # Combine a hash of hashes by combining the keys using the separator
          #  - Separator may be a string or Array
          #   - A string will be used for all levels
          #   - An array will be used in the order its given, when exhausted it will use the last value
          def combine(hash, sep = '.')
            sep = [*sep]
            cur_sep = sep.shift || '.'
            sep = [cur_sep] if sep.empty?

            hash.inject({}) do |h,(k1,v)|
              v = v.is_a?(Hash) ? combine(v,sep): {nil => [*v]}
              v.inject(h) do |h,(k2,val)|
                key = [k1,k2].compact.join(cur_sep)
                if val.is_a?(Array) && val.length == 1
                  val = val.first
                end
                h[key] = val
                h
              end
            end
          end

          # Flatten our hash keys into the correct format
          def hash_to_cgroups(hash)
            combine(hash,['.','_'])
          end

        end

      end
    end
  end
end
