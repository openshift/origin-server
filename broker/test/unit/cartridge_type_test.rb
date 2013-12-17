require_relative '../test_helper'

class CartridgeTypeTest < ActiveSupport::TestCase

  setup do
    Lock.stubs(:lock_application).returns(true)
    Lock.stubs(:unlock_application).returns(true)
  end

  def with_config(sym, value, base=:openshift, &block)
    c = Rails.configuration.send(base)
    @old =  c[sym]
    c[sym] = value
    yield
  ensure
    c[sym] = @old
  end

  def test_create_type
    CartridgeType.where(:name => 'mock').delete

    cart = CartridgeType.new(:name => 'mock')
    assert !cart.save
    cart.streams << CartridgeStream.new
    assert !cart.save
    cart.streams[0].version = "1.0"
    assert cart.save

    assert_equal 'mock-1.0', cart.streams[0].name
    assert_equal 'mock', cart.streams[0].original_name
    assert !cart.streams[0].obsolete?
  end

  def test_duplicate_error
    CartridgeType.where(:name => 'mock').delete

    cart = CartridgeType.new(:name => 'mock', :streams => [CartridgeStream.new(:version => '1.0')])
    assert cart.save
    cart = CartridgeType.new(:name => 'mock', :streams => [CartridgeStream.new(:version => '1.0')])
    assert !cart.save
  end

  def test_latest_cdk
    assert t = open('http://cdk-claytondev.rhcloud.com/manifest/master'){ |f| CartridgeType.from_manifest(OpenShift::Runtime::Manifest.manifests_from_yaml(f)) }
    assert_equal 1, t.streams.length
  end

  def test_from_manifest
    CartridgeType.where(:name => 'jbossas').delete

    path = File.absolute_path('../../../cartridges/openshift-origin-cartridge-jbossas/metadata/manifest.yml', File.dirname(__FILE__))
    versions = OpenShift::Runtime::Manifest.manifests_from_yaml(IO.read(path))
    type = CartridgeType.from_manifest(versions)
    assert type
    assert_equal 'jbossas', type.name
    assert type.streams.length > 0
    assert stream = type.streams[0]
    assert stream.version.chomp =~ /\A\d+(\.\d+)*\Z/, stream.version
    assert_equal "jbossas-#{stream.version}", stream.global_identifier
    assert cartridge = stream.cartridge
    assert OpenShift::Cartridge === cartridge
    [:name, :version, :cartridge_vendor, :version].each do |sym|
      assert_equal stream.send(sym), cartridge.send(sym), "Expected #{sym} to be the same on CartridgeStream and Cartridge"
    end
    type.save!

    methods = OpenShift::Cartridge.instance_methods(false).select{ |sym| sym.to_s =~ /^[a-zA-Z_\d\?]$/ }
    from_yaml = OpenShift::Runtime::Manifest.manifests_from_yaml(IO.read(path)).map{ |m| OpenShift::Cartridge.new.from_descriptor(m.manifest) }
    from_yaml.zip(type.streams.map(&:cartridge)) do |a, b|
      methods.each do |sym|
        assert_equal a.send(sym), b.send(sym), "Expected #{sym} to be the same on Cartridge and CartridgeStream"
      end
    end
  end

  def test_update_manifest
    CartridgeType.where(:name => 'mock').delete

    versions = OpenShift::Runtime::Manifest.manifests_from_yaml(<<-MANIFEST.strip_heredoc)
        ---
        Name: mock
        Cartridge-Short-Name: MOCK
        Display-Name: Mock Cartridge 0.1
        Description: A mock cartridge for development use only.
        Version: '0.1'
        Cartridge-Vendor: redhat
        Categories:
        - mock
        - web_framework
        MANIFEST
    type = CartridgeType.from_manifest(versions)
    assert_equal "mock", type.name
    assert_equal 1, type.streams.length
    assert_equal '0.1', type.streams[0].version
    assert type.streams[0].categories.include?("web_framework")
    type.save!

    versions = OpenShift::Runtime::Manifest.manifests_from_yaml(<<-MANIFEST.strip_heredoc)
        ---
        Name: mock2
        Cartridge-Short-Name: MOCK
        Version: '0.1'
        Cartridge-Vendor: redhat
        MANIFEST
    assert_raises(OpenShift::UserException){ type.update_from_manifest(versions) }
    type.reload

    versions = OpenShift::Runtime::Manifest.manifests_from_yaml(<<-MANIFEST.strip_heredoc)
        ---
        Name: mock
        Cartridge-Short-Name: MOCK
        Display-Name: Mock Cartridge 0.2
        Description: A mock cartridge for development use only.
        Version: '0.2'
        Cartridge-Vendor: redhat
        Categories:
        - mock
        - web_framework
        MANIFEST
    type.update_from_manifest(versions)
    assert_equal 2, type.streams.length
    assert_equal "mock", type.name
    assert type.streams[0].categories.include?("web_framework")
    assert_equal "Mock Cartridge 0.1", type.streams[0].display_name
    assert type.streams[0].obsolete?
    assert_equal "Mock Cartridge 0.2", type.streams[1].display_name
    assert !type.streams[1].obsolete?
    type.save!
  end
end