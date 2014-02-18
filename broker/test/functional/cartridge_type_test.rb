ENV["TEST_NAME"] = "functional_cartridge_type_test"
require_relative '../test_helper'

class CartridgeTypeTest < ActiveSupport::TestCase

  def test_create_type
    CartridgeType.where(:name => 'mock').delete

    cart = CartridgeType.new(:name => 'mock-1.0')
    assert !cart.save
    cart.version = '1.0'
    assert !cart.save
    cart.base_name = 'mock'
    assert !cart.save
    cart.cartridge_vendor = 'other'
    assert !cart.save
    cart.cartridge_vendor = 'redhat'
    assert !cart.save
    cart.provides = cart.names
    cart.save!

    assert_equal 'mock-1.0', cart.global_identifier
    assert_equal 'redhat-mock-1.0', cart.full_identifier
    assert !cart.obsolete?
  end

  def test_is_premium
    cart = stub(:usage_rates => [1])
    CartridgeType.any_instance.expects(:cartridge).returns(cart)
    assert CartridgeType.new.is_premium?
  end

  def test_is_not_premium
    cart = stub(:usage_rates => [])
    CartridgeType.any_instance.expects(:cartridge).returns(cart)
    assert !CartridgeType.new.is_premium?
  end

  def test_duplicate_error
    CartridgeType.where(:name => 'mock-1.0').delete

    cart = CartridgeType.new(:name => 'mock-1.0', :base_name => 'mock', :version => '1.0', :cartridge_vendor => 'redhat', :provides => ['mock-1.0'])
    cart.save!
    cart = CartridgeType.new(:name => 'mock-1.0', :base_name => 'mock', :version => '1.0', :cartridge_vendor => 'redhat', :provides => ['mock-1.0'])
    assert cart.activate, cart.errors.full_messages.join("\n")
    assert_equal cart._id, CartridgeType.active.where(name: 'mock-1.0').first._id
  end

  def test_latest_cdk
    CartridgeType.where(:base_name => 'cdk').delete
    assert t = open('http://cdk-claytondev.rhcloud.com/manifest/master'){ |f| CartridgeType.update_from(OpenShift::Runtime::Manifest.manifests_from_yaml(f)) }
    assert t.length > 0
    assert t.none?(&:persisted?)
    assert t.all?{ |type| type.base_name == 'cdk' }
    assert t.all?{ |type| type.base_name == 'cdk' }
    assert t.none?{ |type| type.cartridge_vendor.nil? }
  end

  def test_known_cdk
    CartridgeType.where(:base_name => 'cdk').delete
    url = 'https://cdk-claytondev.rhcloud.com/manifest/2694fe21bfac5126616da4664c4263747698e825'
    assert t = open(url){ |f| CartridgeType.update_from(OpenShift::Runtime::Manifest.manifests_from_yaml(f), url) }
    assert_equal 1, t.length
    assert type = t[0]
    assert_equal "cdk", type.base_name
    assert_equal "1.0", type.version
    assert_equal "smarterclayton", type.cartridge_vendor
    assert_equal url, type.manifest_url
    type.save!

    type = CartridgeType.find_by(name: type.name)
    assert_equal type.manifest_url, type.cartridge.manifest_url

  end

  def test_from_manifest
    CartridgeType.where(:base_name => 'jbossas').delete

    path = File.absolute_path('../../../cartridges/openshift-origin-cartridge-jbossas/metadata/manifest.yml', File.dirname(__FILE__))
    versions = OpenShift::Runtime::Manifest.manifests_from_yaml(IO.read(path))
    assert types = CartridgeType.update_from(versions)
    assert types.none?(&:persisted?)
    assert type = types[0]
    assert_equal 'jbossas', type.base_name
    assert_equal 'jbossas', type.original_name
    assert type.version.chomp =~ /\A\d+(\.\d+)*\Z/, type.version
    assert_equal "jbossas-#{type.version}", type.global_identifier
    assert_equal type.name, type.global_identifier
    assert cartridge = type.cartridge
    assert OpenShift::Cartridge === cartridge
    [:name, :version, :cartridge_vendor, :version].each do |sym|
      assert_equal type.send(sym), cartridge.send(sym), "Expected #{sym} to be the same on CartridgeType and Cartridge"
    end
    type.save!

    type = CartridgeType.find_by(name: type.name)
    assert_equal type.manifest_url, type.cartridge.manifest_url

    methods = OpenShift::Cartridge.instance_methods(false).select{ |sym| sym.to_s =~ /^[a-zA-Z_\d\?]$/ }
    from_yaml = OpenShift::Runtime::Manifest.manifests_from_yaml(IO.read(path)).map{ |m| OpenShift::Cartridge.new.from_descriptor(m.manifest) }
    from_yaml.zip(types.map(&:cartridge)) do |a, b|
      methods.each do |sym|
        assert_equal a.send(sym), b.send(sym), "Expected #{sym} to be the same on Cartridge and CartridgeType"
      end
    end
  end

  def test_update_manifest
    CartridgeType.where(:base_name => 'mock').delete

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
    types = CartridgeType.update_from(versions, "manifest://test")
    assert_equal 1, types.length
    assert type = types[0]
    assert_equal "mock-0.1", type.name
    assert_equal '0.1', type.version
    assert type.categories.include?("web_framework")
    type.save!

    versions = OpenShift::Runtime::Manifest.manifests_from_yaml(<<-MANIFEST.strip_heredoc)
        ---
        Name: mock
        Cartridge-Short-Name: MOCK
        Display-Name: Mock Cartridge 0.2
        Description: A mock cartridge for development use only.
        Version: '0.2'
        Versions: ['0.1', '0.2']
        Cartridge-Vendor: redhat
        Cartridge-Version: 0.1.0-ab3c4
        Categories:
        - mock
        - web_framework
        - bar
        Version-Overrides:
          '0.1':
            Obsolete: true
        MANIFEST
    types = CartridgeType.update_from(versions, "manifest://test2")
    assert_equal 2, types.length

    assert type = types.find{ |t| t.has_predecessor? }
    assert_equal 'mock-0.1', type.name
    assert type.changed?
    assert type.display_name_changed?
    assert_equal "Mock Cartridge 0.2", type.display_name
    assert type.categories_changed?
    assert_equal ['mock', 'web_framework', 'bar'], type.categories
    assert type.obsolete_changed?
    assert type.obsolete?
    assert type.is_obsolete?
    assert type.manifest_url_changed?
    assert_equal "manifest://test2", type.manifest_url
    assert_equal "0.1.0-ab3c4", type.cartridge_version
    assert type.save!

    assert type = types.find{ |t| !t.persisted? && !t.has_predecessor? }
    assert_equal 'mock-0.2', type.name
    assert_equal "manifest://test2", type.manifest_url
    assert_equal "0.1.0-ab3c4", type.cartridge_version
    assert type.changed?
    assert type.save!
  end
end
