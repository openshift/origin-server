require 'active_support/test_case'
require 'action_controller/test_case'

def gen_uuid
  %x[/usr/bin/uuidgen].gsub('-', '').strip
end

class ActiveSupport::TestCase
  setup{ Mongoid.identity_map_enabled = false }

  def cartridge_instances_for(*args)
    args.map do |sym|
      CartridgeCache.find_all_cartridges(sym.to_s).sort_by(&OpenShift::Cartridge::VERSION_ORDER).last or raise "Unable to find cartridge for #{sym}"
    end.map! do |c|
      CartridgeInstance.new(c)
    end
  end

  def try_cartridge_instances_for(sym)
    begin
      instances_list = cartridge_instances_for(sym)
      return instances_list if instances_list.length > 0
    rescue RuntimeError
      # When the requested cartridge is not available, try PHP.
      return cartridge_instances_for(:php)
    end
  end

  # This list includes cartridges that are installed with all versions of OpenShift
  [:php, :ruby, :mysql, :'jenkins-client', :jenkins, :haproxy].each do |sym|
    define_method "#{sym}_version" do
      (@version ||= {})[sym] ||= cartridge_instances_for(sym).first.name
    end
  end

  # This list includes cartridges that are _not_ installed with all versions of OpenShift.
  # Be aware that try_cartridge_instances_for will return info about the PHP cartridge
  # when the requested type is not available.
  [:jbosseap].each do |sym|
    define_method "#{sym}_version" do
      (@version ||= {})[sym] ||= try_cartridge_instances_for(sym).first.name
    end
  end

  # e.g.: stubs_config :openshift, :foo => "bar", :baz => "booyah"
  def stubs_config(sym, with)
    hash = Rails.configuration.send sym
    Rails.configuration.stubs(sym).returns(hash.merge(with))
  end

  def with_config(sym, value, base=:openshift, &block)
    c = Rails.configuration.send(base)
    @old =  c[sym]
    c[sym] = value
    yield
  ensure
    c[sym] = @old
  end
end

class ActionController::TestCase
  #
  # Clear all instance variables not set by rails before
  # a request is executed
  #
  def allow_multiple_execution(c=@controller)
    e = c.instance_eval{ class << self; self; end }
    e.send(:define_method, :reset_instance_variables) do
      instance_variables.select{ |sym| sym.to_s =~ /\A@[^_]/ }.each{ |sym| instance_variable_set(sym, nil) }
    end
    e.prepend_before_filter :reset_instance_variables
    c
  end

  def json_messages(&block)
    assert json = JSON.parse(response.body)
    assert messages = json['messages']
    yield messages if block_given?
    messages
  end
end

def read_local_cartridges
  $global_cartridges ||= begin
    sources = [
      ENV['CARTRIDGE_PATH'] || '.',
      # we're in a source origin-server repo
      File.expand_path('../../../../cartridges', __FILE__),
      # we're on a node or all in one server
      '/var/lib/openshift/.cartridge_repository',
    ]
    manifests = sources.inject do |arr, base_path|
      manifests = Dir["#{base_path}/**/manifest.yml"].presence or next
      if env = (ENV['CARTRIDGE_SUFFIX'] || 'rhel*')
        manifests += Dir["#{base_path}/**/manifest.yml.#{env}"].to_a
      end
      break manifests
    end or raise "Unable to find system cartridges in #{sources.join(', ')}"

    manifests.map do |f|
      OpenShift::Runtime::Manifest.manifests_from_yaml(IO.read(f)).map do |m|
        OpenShift::Cartridge.new.from_descriptor(m.manifest)
      end rescue raise "Unable to parse manifest: #{$!.message} (#{f})\n#{$!.backtrace.join("\n")}"
    end.flatten
  end
end

def stubber
  return if @container
  $container ||= OpenShift::ApplicationContainerProxy.instance('test-node-id')#OpenShift::ApplicationContainerProxy.find_one
  $cartridges ||= begin
    carts = read_local_cartridges#$container.get_available_cartridges
    carts.freeze
  end

  c = $container
  c.stubs(:get_available_cartridges).returns(carts)
  c.stubs(:reserve_uid).returns(555)
  c.stubs(:unreserve_uid)
  c.stubs(:restart).returns(ResultIO.new)
  c.stubs(:reload).returns(ResultIO.new)
  c.stubs(:stop).returns(ResultIO.new)
  c.stubs(:force_stop).returns(ResultIO.new)
  c.stubs(:start).returns(ResultIO.new)
  c.stubs(:add_alias).returns(ResultIO.new)
  c.stubs(:remove_alias).returns(ResultIO.new)
  c.stubs(:add_aliases).returns(ResultIO.new)
  c.stubs(:remove_aliases).returns(ResultIO.new)
  c.stubs(:add_ssl_cert).returns(ResultIO.new)
  c.stubs(:remove_ssl_cert).returns(ResultIO.new)
  c.stubs(:tidy).returns(ResultIO.new)
  c.stubs(:threaddump).returns(ResultIO.new)
  c.stubs(:create).returns(ResultIO.new)
  c.stubs(:destroy).returns(ResultIO.new)
  c.stubs(:update_namespace).returns(ResultIO.new)
  c.stubs(:add_component).returns(ResultIO.new)
  c.stubs(:post_configure_component).returns(ResultIO.new)
  c.stubs(:remove_component).returns(ResultIO.new)
  c.stubs(:get_public_hostname).returns("node_dns")
  c.stubs(:set_quota).returns(ResultIO.new)
  c.stubs(:set_user_env_vars).returns(ResultIO.new)
  c.stubs(:unset_user_env_vars).returns(ResultIO.new)
  c.stubs(:update_cluster).returns(ResultIO.new)
  c.stubs(:deploy).returns(ResultIO.new)
  c.stubs(:activate).returns(ResultIO.new)
  c.stubs(:status).returns(ResultIO.new)
  c.stubs(:update_cluster).returns(ResultIO.new)
  c.stubs(:get_quota_files).returns(10000)
  c.stubs(:get_update_cluster_job).returns(RemoteJob.new(nil, nil, nil))
  c.stubs(:execute_direct).raises(StandardError.new("Unstubbed call to execute_direct"))
  c.stubs(:rpc_get_fact_direct).raises(StandardError.new("Unstubbed call to rpc_get_fact_direct"))
  @container = c

  CartridgeCache.stubs(:get_all_cartridges).returns($cartridges)
  OpenShift::ApplicationContainerProxy.stubs(:execute_parallel_jobs)
  RemoteJob.stubs(:get_parallel_run_results)
  OpenShift::ApplicationContainerProxy.stubs(:find_available).returns(@container)
  OpenShift::ApplicationContainerProxy.stubs(:find_one).returns(@container)
  OpenShift::ApplicationContainerProxy.stubs(:get_blacklisted).returns(["redhat", "openshift"])

  dns = mock()
  OpenShift::DnsService.stubs(:instance).returns(dns)
  dns.stubs(:register_application)
  dns.stubs(:deregister_application)
  dns.stubs(:publish)
  dns.stubs(:close)
  Gear.any_instance.stubs(:get_proxy).returns(@container)
  Gear.stubs(:base_filesystem_gb).returns(1)
  Gear.stubs(:get_gear_states).returns("")
  Rails.cache.clear
end
