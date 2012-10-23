# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
ActiveSupport::Inflector.inflections do |inflect|

end

#
# From Rails 3.2
#
module ActiveSupport::Inflector
  def safe_constantize(camel_cased_word)
    begin
      constantize(camel_cased_word)
    rescue NameError => e
      raise unless e.message =~ /(uninitialized constant|wrong constant name) #{const_regexp(camel_cased_word)}$/ ||
        e.name.to_s == camel_cased_word.to_s
    rescue ArgumentError => e
      raise unless e.message =~ /not missing constant #{const_regexp(camel_cased_word)}\!$/
    end
  end
  # Mount a regular expression that will match part by part of the constant.
  # For instance, Foo::Bar::Baz will generate Foo(::Bar(::Baz)?)?
  def const_regexp(camel_cased_word) #:nodoc:
    parts = camel_cased_word.split("::")
    last = parts.pop

    parts.reverse.inject(last) do |acc, part|
      part.empty? ? acc : "#{part}(::#{acc})?"
    end
  end
end
class String
  def safe_constantize
    ActiveSupport::Inflector.safe_constantize(self)
  end
end
