require 'rubygems'
require 'bundler'
Bundler.setup
require 'active_support'
require 'test/unit'
require 'mocha'

require 'ddns/named_service'

require 'dnsruby'
require 'lib/stickshift-controller/lib/stickshift/dns_service'
require 'lib/stickshift-controller/lib/stickshift/bind_dns_service'


class BindDnsServiceTest < ActiveSupport::TestCase
  include StickShift

  # this is here so I can comment tests out
  def self.notest(t)

  end

  def setup
    super
    @dns_root = File.dirname(File.dirname(__FILE__)) + "/ddns"

    load "#{@dns_root}/authconfig.rb" if not defined? $config
    @config = {
        :server => '127.0.0.1',
        :port => 10053,
        :keyname => 'example.com',
        :keyvalue => 'H6NDDnTbNpcBrUM5c4BJtohyK2uuZ5Oi6jxg3ME+RJsNl5Wl2B87oL12YxWUR3Gp7FdZQojTKBSfs5ZjghYxGw==',
        :zone => "example.com",
        :domain_suffix => "example.com"
    }

    @named = BindTestService.new @dns_root
    @named.start
    sleep 2

    #begin
    #  puts "Checking presence of config information"
    #  puts "Rails.application.config = #{Rails.application.config}"
    #rescue
    #  puts "Rails config is not present"
    #end

    @resolver = Dnsruby::Resolver.new(:nameserver => @config[:server],
                                      :port => @config[:port])
  end

  # 
  test "namespace is registered?" do
    # verify that the namespace is not registered
    client = BindDnsService.new @config
    assert(client.server, "127.0.0.1")
    assert(client.namespace_available?('missing'), 'namespace reported in use when available')
    assert(!client.namespace_available?('testns1'), 'namespace reported available when in use')
  end

  test "register a namespace" do
    client = BindDnsService.new @config
    
    testns = "testns2"
    #assert(client.server, "127.0.0.1")
    #assert(client.namespace_available?(namespace))

    client.register_namespace(testns)

    fqdn = "#{testns}.#{@config[:domain_suffix]}"

    result = nil
    assert_nothing_raised do
      # request
      result = @resolver.query(fqdn, Dnsruby::Types::TXT)
    end

    # check for success: result is Dnsruby::Message
    assert_instance_of(Dnsruby::Message, result)

    # result.answer.count = 1
    assert_equal(1, result.answer.count, "expected 1 result, got #{result.answer.count}")
    
    # result.answer[0].name.to_s = fqdn
    assert_equal(fqdn, result.answer[0].name.to_s, "expected FQDN #{fqdn}")

  end

  test "deregister a namespace" do
    client = BindDnsService.new @config
    
    testns = "testns1"
    fqdn = "#{testns}.#{@config[:domain_suffix]}"

    #assert(client.server, "127.0.0.1")
    #assert(client.namespace_available?(namespace))

    client.deregister_namespace(testns)
    
    result = nil
    assert_raise Dnsruby::NXDomain do
      # request
      result = @resolver.query(fqdn, Dnsruby::Types::TXT)
    end
    
  end

  test "register an application" do
    client = BindDnsService.new @config
    
    testns = "testns3"
    testapp = "testapp3"
    fqdn = "#{testapp}-#{testns}.#{@config[:domain_suffix]}"
    nodename = "node.#{@config[:domain_suffix]}"

    # add the app
    client.register_application(testapp, testns, nodename)
    
    # now check that it's there
    result = nil
    assert_nothing_raised do
      # request
      result = @resolver.query(fqdn, 'CNAME')
    end

    # check for success: result is Dnsruby::Message
    assert_instance_of(Dnsruby::Message, result)

    # result.answer.count = 1
    assert_equal(1, result.answer.count, "expected 1 result, got #{result.answer.count}")

    # result.answer[0].name.to_s = fqdn
    assert_equal(nodename, result.answer[0].rdata.to_s, "expected FQDN #{nodename}")
    
  end

  test "deregister an application" do
    client = BindDnsService.new @config
    
    testns = "testns4"
    testapp = "testapp4"
    fqdn = "#{testapp}-#{testns}.#{@config[:domain_suffix]}"
    nodename = "node.#{@config[:domain_suffix]}"

    # add the app
    client.deregister_application(testapp, testns)
    sleep 2

    lookup = Dnsruby::Resolver.new(
                                   :nameserver => @config[:server],
                                   :port => @config[:port])

    result = nil
    assert_raise Dnsruby::NXDomain do
      # request
      #result = resolver.query(fqdn, 'CNAME')
      result = lookup.query(fqdn, 'CNAME')
    end
  end

  def teardown
    super
    @named.stop
    @named.clean
  end

end
