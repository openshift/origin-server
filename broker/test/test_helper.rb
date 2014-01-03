require File.expand_path('../coverage_helper.rb', __FILE__)

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'mocha/setup'

=begin
begin
  manifest = YAML.load(File.open(Dir["/var/lib/openshift/.cartridge_repository/redhat-php/*/metadata/manifest.yml"].first))
  php_version = "php-" + manifest['Version']

  manifest = YAML.load(File.open(Dir["/var/lib/openshift/.cartridge_repository/redhat-ruby/*/metadata/manifest.yml"].first))
  ruby_version = "ruby-" + manifest['Version']

  if File.exist?("/var/lib/openshift/.cartridge_repository/redhat-mysql")
    manifest = YAML.load(File.open(Dir["/var/lib/openshift/.cartridge_repository/redhat-mysql/*/metadata/manifest.yml"].first))
    mysql_version = "mysql-" + manifest['Version']
  end

  if File.exist?("/var/lib/openshift/.cartridge_repository/redhat-mariadb")
    manifest = YAML.load(File.open(Dir["/var/lib/openshift/.cartridge_repository/redhat-mariadb/*/metadata/manifest.yml"].first))
    mysql_version = "mariadb-" + manifest['Version']
  end
rescue => e
  puts "Unable to set PHP/RUBY/MYSQL versions, #{e.backtrace.join("\n")}"
  [:php_version, :mysql_version, :ruby_version].each{ |sym| Kernel.const_set(sym, ENV[sym.to_s]) }
end
=end

def gen_uuid
  %x[/usr/bin/uuidgen].gsub('-', '').strip 
end

def register_user(login=nil, password=nil)
  if ENV['REGISTER_USER']
    if File.exists?("/etc/openshift/plugins.d/openshift-origin-auth-remote-user.conf")
      `/usr/bin/htpasswd -b /etc/openshift/htpasswd #{login} #{password} > /dev/null 2>&1`
    else
      accnt = UserAccount.new(user: login, password: password)
      accnt.save
    end
  end
end

require 'active_support/test_case'
class ActiveSupport::TestCase
  setup{ Mongoid.identity_map_enabled = false }

  def cartridge_instances_for(*args)
    args.map do |sym|
      CartridgeCache.find_all_cartridges(sym.to_s).sort_by(&OpenShift::Cartridge::VERSION_ORDER).last or raise "Unable to find cartridge for #{sym}"
    end.map! do |c|
      CartridgeInstance.new(c)
    end
  end

  [:php, :ruby, :mysql].each do |sym|
    define_method "#{sym}_version" do
      (@version ||= {})[sym] ||= cartridge_instances_for(sym).first.name
    end
  end
end

require 'action_controller/test_case'
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
end

def read_local_cartridges
  $global_cartridges ||= begin
    manifests = Dir[File.expand_path('../../../cartridges/**/manifest.yml', __FILE__)].to_a
    if env = (ENV['CARTRIDGE_SUFFIX'] || 'rhel*')
      manifests += Dir[File.expand_path("../../../cartridges/**/manifest.yml.#{env}", __FILE__)].to_a
    end
    manifests.map do |f|
      OpenShift::Runtime::Manifest.manifests_from_yaml(IO.read(f)).map do |m|
        OpenShift::Cartridge.new.from_descriptor(m.manifest)
      end
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
