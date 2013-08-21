#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

module OpenShift
  # Helper hash subclass with three purposes:
  # 1. Give a type to the objects returned, rather than just being Hashes.
  # 2. Provide attribute readers that fail if the key is missing,
  #    to help detect mistakes faster.
  # 3. Simplify serialization by making all keys strings, not symbols, but
  #    still allowing key access by symbol.
  class HashWithReaders < Hash
    class NoSuchKey < StandardError; end

    # Keys switched from symbols to strings -
    # so, translate for any code already accessing by symbol.
    def [](key); super(key.to_s); end
    def []=(key, *args); super(key.to_s, *args); end
    def has_key?(key); super(key.to_s); end
    def merge(hash); self.clone.merge! hash; end
    def merge!(hash)
      hash.each {|k,v| self[k] = v} #ah, but now keys are converted to string.
      self
    end

    # provide readers for keys
    def method_missing(sym, *args)
      # don't screen other things that operate via method_missing
      return super if [:to_ary, :to_json, :to_yaml, :to_xml].include? sym
      key = sym.to_s
      return self[key] if self.has_key? key
      raise NoSuchKey.new("#{self.class} has no key #{sym}: #{self.inspect}")
    end
    def respond_to?(sym, *args)
      has_key?(sym) || super
    end

    # make classes easily identified in output
    def to_s; "#{self.class} #{super}"; end
    def inspect; "#{self.class} #{super}"; end
    def pretty_inspect; "#{self.class} #{super}"; end

    # Convert Hash subclasses into plain hashes for YAML/XML dump.
    # Assumptions:
    #   Hash keys will be strings - don't need to clear them
    #   No custom objects with Hash subclass contents
    def self.deep_clear_subclasses(obj)
      deep_convert(obj, {}, lambda { Hash.new })
    end

    # Convert plain hashes into HashWithReaders
    # Assumptions:
    #   Hash keys will be strings - don't need to convert them
    #   No custom objects with Hash subclass contents
    def self.deep_convert_hashes(obj)
      deep_convert(obj, {}, lambda { HashWithReaders.new })
    end

    private
    def self.deep_convert(obj, dedup, new_lambda)
      id = obj.__id__ # used to deduplicate converted copies
      case obj
      when Hash
        return dedup[id] if dedup.has_key? id
        dedup[id] = copy = new_lambda.call
        obj.each {|k,v| copy[k.to_s] = deep_convert(v, dedup, new_lambda)}
        copy
      when Array
        return dedup[id] if dedup.has_key? id
        obj.inject(dedup[id] = []) {|a,v| a << deep_convert(v, dedup, new_lambda)}
      else
        obj # not going to operate on other kinds of objects
      end
    end
  end
end

