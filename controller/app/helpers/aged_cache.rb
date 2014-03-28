#
# Based on http://stackoverflow.com/a/16161783 on implementation by Sam Saffron
#
class AgedCache

  def initialize(max_size)
    @max_size = max_size
    @data = {}
  end

  def max_size=(size)
    raise ArgumentError.new(:max_size) if @max_size < 1
    @max_size = size
    if @max_size < @data.size
      @data.keys[0..@max_size-@data.size].each do |k|
        @data.delete(k)
      end
    end
  end

  def [](key)
    found = true
    value = @data.delete(key){ found = false }
    if found
      @data[key] = value
    else
      nil
    end
  end

  def []=(key,val)
    @data.delete(key)
    @data[key] = val
    if @data.length > @max_size
      @data.delete(@data.first[0])
    end
    val
  end

  def each
    @data.reverse.each do |pair|
      yield pair
    end
  end

  # used further up the chain, non thread safe each
  alias_method :each_unsafe, :each

  def to_a
    @data.to_a.reverse
  end

  def delete(k)
    @data.delete(k)
  end

  def clear
    @data.clear
  end

  def count
    @data.count
  end

  # for cache validation only, ensures all is sound
  def valid?
    true
  end
end