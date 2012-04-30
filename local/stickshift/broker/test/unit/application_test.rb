require 'test_helper'
require 'stickshift-controller'
require 'mocha'

module Rails
  def self.logger
    l = Mocha::Mock.new("logger")
    l.expects(:debug)
    l
  end
end

class ApplicationTest < ActiveSupport::TestCase
=begin
  test "create" do
    observer_seq = sequence("observer_seq")
    cart = StickShift::Cartridge.new.from_descriptor({ 'Name' => 'dummy' } )
    CartridgeCache.expects(:find_cartridge).returns(cart).at_least_once
    Gear.any_instance.stubs(:create).returns(ResultIO.new)
    Application.any_instance.stubs(:framework).returns('dummy')
    Application.any_instance.stubs(:add_dns).returns(nil)
    Application.any_instance.stubs(:add_node_settings).returns(nil)
    Gear.any_instance.stubs(:get_proxy).returns(StickShift::ApplicationContainerProxy.instance("asldksd"))
    StickShift::ApplicationContainerProxy.any_instance.stubs(:get_public_hostname).returns("foo.bar")
    
    user = mock("user")
    user.stubs(:applications).returns([])
    # user.expects(:namespace).returns("dummy_namespace") 
    Application.expects(:notify_observers).with(:before_application_create, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:application_creation_success, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_application_create, anything).in_sequence(observer_seq).once
    application = Application.new(user, "app_name", "app_uuid", "small", "dummy")
    application.expects(:save).returns(nil).at_least_once
    application.create
  end
  
  
  test "configure_dependencies" do    
    user = mock("user")
    user.stubs(:save_jobs).returns(false)
    user.stubs(:applications).returns([])
    # user.expects(:namespace).returns("dummy_namespace")
    Application.any_instance.stubs(:framework).returns('dummy')
    Application.any_instance.stubs(:add_dns).returns(nil)
    Application.any_instance.stubs(:add_node_settings).returns(nil)
    Gear.any_instance.stubs(:get_proxy).returns(StickShift::ApplicationContainerProxy.instance("asldksd"))
    StickShift::ApplicationContainerProxy.any_instance.stubs(:get_public_hostname).returns("foo.bar")
    application = Application.new(user, "app_name", "app_uuid", "small", "dummy")
    
    observer_seq = sequence("observer_seq")
    Application.expects(:notify_observers).with(:before_application_create, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:application_creation_success, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_application_create, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:before_application_configure, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_application_configure, anything).in_sequence(observer_seq).once
    cart = StickShift::Cartridge.new.from_descriptor({ 'Name' => 'dummy' } )
    CartridgeCache.expects(:find_cartridge).returns(cart).at_least_once
    Gear.any_instance.stubs(:create).returns(ResultIO.new)
    Gear.any_instance.stubs(:configure).returns(ResultIO.new)
    application.expects(:save).returns(nil).at_least_once
    
    application.create
    application.configure_dependencies
  end
  
  test "deconfigure_dependencies" do
    user = mock("user")
    user.stubs(:save_jobs).returns(false)
    user.stubs(:applications).returns([])
    # user.expects(:namespace).returns("dummy_namespace") 
    Application.any_instance.stubs(:framework).returns('dummy')
    Application.any_instance.stubs(:add_dns).returns(nil)
    Application.any_instance.stubs(:add_node_settings).returns(nil)
    Gear.any_instance.stubs(:get_proxy).returns(StickShift::ApplicationContainerProxy.instance("asldksd"))
    StickShift::ApplicationContainerProxy.any_instance.stubs(:get_public_hostname).returns("foo.bar")
    application = Application.new(user, "app_name", "app_uuid", "small", "dummy")
    
    observer_seq = sequence("observer_seq")
    Application.expects(:notify_observers).with(:before_application_create, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:application_creation_success, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_application_create, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:before_application_configure, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_application_configure, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:before_application_deconfigure, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_application_deconfigure, anything).in_sequence(observer_seq).once
    cart = StickShift::Cartridge.new.from_descriptor({ 'Name' => 'dummy' } )
    CartridgeCache.expects(:find_cartridge).returns(cart).at_least_once
    Gear.any_instance.stubs(:create).returns(ResultIO.new)
    Gear.any_instance.stubs(:configure).returns(ResultIO.new)
    Gear.any_instance.stubs(:deconfigure).returns(ResultIO.new)
    application.expects(:save).returns(nil).at_least_once
    
    application.create
    application.configure_dependencies
    application.deconfigure_dependencies
  end
  
  test "destroy" do
    observer_seq = sequence("observer_seq")
    
    user = mock("user")
    Application.expects(:notify_observers).with(:before_application_destroy, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_application_destroy, anything).in_sequence(observer_seq).once
    application = Application.new(user, "app_name", "app_uuid", "small", "dummy")
    application.expects(:save).returns(nil).at_most(1)
    
    application.destroy
  end

  test "create_dns" do
    user = mock("user")    
    application = Application.new(user, "app_name", "app_uuid", "small", "php-5.3")
    
    observer_seq = sequence("observer_seq")
    Application.expects(:notify_observers).with(:before_create_dns, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_create_dns, anything).in_sequence(observer_seq).once
    
    user.expects(:namespace).returns("kraman")    
    StickShift::DnsService.instance.class.any_instance.expects(:register_application).once
    StickShift::DnsService.instance.class.any_instance.expects(:publish).once
    StickShift::DnsService.instance.class.any_instance.expects(:close).once    
    application.expects(:container).returns(StickShift::ApplicationContainerProxy.instance("asldksd"))
    StickShift::ApplicationContainerProxy.any_instance.stubs(:get_public_hostname).returns("foo.bar")

    application.create_dns
  end

  test "destroy_dns" do
    user = mock("user")    
    application = Application.new(user, "app_name", "app_uuid", "small", "php-5.3")
    
    observer_seq = sequence("observer_seq")
    Application.expects(:notify_observers).with(:before_destroy_dns, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_destroy_dns, anything).in_sequence(observer_seq).once
    
    StickShift::DnsService.instance.class.any_instance.expects(:deregister_application).once
    StickShift::DnsService.instance.class.any_instance.expects(:publish).once
    StickShift::DnsService.instance.class.any_instance.expects(:close).once    
    user.expects(:namespace).returns("kraman")    

    application.destroy_dns
  end
  
  test "recreate_dns" do    
    user = mock("user")    
    application = Application.new(user, "app_name", "app_uuid", "small", "php-5.3")
    
    observer_seq = sequence("observer_seq")
    Application.expects(:notify_observers).with(:before_recreate_dns, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_recreate_dns, anything).in_sequence(observer_seq).once

    StickShift::DnsService.instance.class.any_instance.expects(:deregister_application).once
    StickShift::DnsService.instance.class.any_instance.expects(:register_application).once
    StickShift::DnsService.instance.class.any_instance.expects(:publish).once
    StickShift::DnsService.instance.class.any_instance.expects(:close).once    
    user.expects(:namespace).returns("kraman").twice
    application.expects(:container).returns(StickShift::ApplicationContainerProxy.instance("asldksd"))
    StickShift::ApplicationContainerProxy.any_instance.stubs(:get_public_hostname).returns("foo.bar")

    application.recreate_dns
  end
  
  test "add alias" do
    user = mock("user")
    CartridgeCache.expects(:cartridge_names).returns(["php-5.3"]).once
    container = mock("ApplicationContainerProxy")
    container.expects(:add_alias).returns(ResultIO.new).once
    application = Application.new(user, "app_name", "app_uuid", "small", "php-5.3")
    application.expects(:container).returns(container).once
    application.expects(:save).once
    application.add_alias("foo.bar.com")
  end
  
  test "remove alias" do    
    user = mock("user")
    CartridgeCache.expects(:cartridge_names).returns(["php-5.3"])
    container = mock("ApplicationContainerProxy")
    container.expects(:remove_alias).returns(ResultIO.new).once
    application = Application.new(user, "app_name", "app_uuid", "small", "php-5.3")
    application.expects(:aliases).returns(["foo.bar.com"]).at_least_once    
    application.expects(:container).returns(container).once
    application.expects(:save).once
    application.remove_alias("foo.bar.com")
  end

  test "add dependency" do
    user = mock("user")    
    application = Application.new(user, "app_name", "app_uuid", "small", "php-5.3")
    
    CartridgeCache.expects(:cartridge_names).with('embedded').returns([])
    observer_seq = sequence("observer_seq")
    Application.expects(:notify_observers).with(:before_add_dependency, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_add_dependency, anything).in_sequence(observer_seq).once
    Application.any_instance.stubs(:configure_dependencies).returns(ResultIO.new)

    
    application.add_dependency("foo")
  end

  test "remove dependency" do
    user = mock("user")    
    application = Application.new(user, "app_name", "app_uuid", "small", "php-5.3")
    
    observer_seq = sequence("observer_seq")
    Application.expects(:notify_observers).with(:before_remove_dependency, anything).in_sequence(observer_seq).once
    Application.expects(:notify_observers).with(:after_remove_dependency, anything).in_sequence(observer_seq).once

    Application.any_instance.stubs(:configure_dependencies).returns(ResultIO.new)
    Application.any_instance.stubs(:embedded).returns({"foo" => { "info" => nil } })
    
    application.remove_dependency("foo")    
  end
=end
end
