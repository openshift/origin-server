require 'mocha'
require "pp"

class ActiveSupport::TestCase

  def gen_small_uuid()
    %x[/usr/bin/uuidgen].gsub('-', '').strip
  end

  def uuid
    @uuid ||= new_uuid
  end
  def new_uuid
    "#{Time.now.to_i}#{gen_small_uuid[0,6]}"
  end

  @@name = 0
  def unique_name_format
    'name%i'
  end
  def unique_name(format=nil)
    (format || unique_name_format) % self.class.next
  end
  def self.next
    @@name += 1
  end

  @@once = []
  def once(symbol, &block)
    unless @@once.include? symbol
      @@once << symbol
      exit_block = yield block
      at_exit do
        exit_block.call
      end
    end
  end
end

