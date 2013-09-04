require 'rubygems'
require 'test/unit'
require 'mocha/setup'
require 'logger'
require 'securerandom'
require 'active_support/core_ext/class/attribute'

class PluginTestCase < MiniTest::Unit::TestCase
  attr_reader :container_uuid

  def before_setup
    @container_uuid = SecureRandom.uuid.gsub('-', '')
  end
end
