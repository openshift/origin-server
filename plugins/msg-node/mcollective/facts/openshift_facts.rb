require 'rubygems'
require 'parseconfig'

def get_node_config_value(key, default)
  config_file = ParseConfig.new('/etc/openshift/node.conf')
  val = config_file.get_value(key)
  return default if val.nil?
  val.gsub!(/\\:/,":") if not val.nil?
  val.gsub!(/[ \t]*#[^\n]*/,"") if not val.nil?
  val = val[1..-2] if not val.nil? and val.start_with? "\""
  val
end

#
# Setup the district
#
district_uuid = 'NONE'
district_active = false
district_conf = '/var/lib/openshift/.settings/district.info'
if File.exists?(district_conf)
  config_file = ParseConfig.new(district_conf)
  district_uuid = config_file.get_value('uuid') ? config_file.get_value('uuid') : 'NONE'
  district_active = config_file.get_value('active') ? config_file.get_value('active') == "true" : false
end
Facter.add(:district_uuid) { setcode { district_uuid } }
Facter.add(:district_active) { setcode { district_active } }

#
# Pull public_ip and public_hostname out of the node_data config
#
public_ip = get_node_config_value("PUBLIC_IP", "UNKNOWN").gsub(/['"]/,"")
public_hostname = get_node_config_value("PUBLIC_HOSTNAME", "UNKNOWN").gsub(/['"]/,"")
Facter.add(:public_ip) { setcode { public_ip } }
Facter.add(:public_hostname) { setcode { public_hostname } }

#
# Find node_profile, max_apps, max_active_apps
#
node_profile = 'small'
max_apps = '0'
max_active_apps = '0'
if File.exists?('/etc/openshift/resource_limits.conf')
  config_file = ParseConfig.new('/etc/openshift/resource_limits.conf')
  node_profile = config_file.get_value('node_profile') || 'small'
  max_apps = config_file.get_value('max_apps') || '0'
  max_active_apps = config_file.get_value('max_active_apps') || '0'
  quota_blocks = config_file.get_value('quota_blocks') || '1048576'
  quota_files = config_file.get_value('quota_files') || '40000'
end

Facter.add(:node_profile) { setcode { node_profile } }
Facter.add(:max_apps) { setcode { max_apps } }
Facter.add(:max_active_apps) { setcode { max_active_apps } }
Facter.add(:quota_blocks) { setcode { quota_blocks } }
Facter.add(:quota_files) { setcode { quota_files } }

#
# Count number of git repos and stopped apps
#
git_repos_count = 0
stopped_app_count = 0
Dir.glob("/var/lib/openshift/*").each do |app_dir|
  if File.directory?(app_dir) && !File.symlink?(app_dir)
    git_repos_count += Dir.glob(File.join(app_dir, "git/*.git")).count

    Dir.glob(File.join(app_dir, %w{app-root runtime .state})).each do |file|
      state = File.read(file).chomp
      if 'idle' == state
        stopped_app_count += 1
      elsif 'stopped' == state
        stopped_app_count += 1
      end
    end
  end
end

Facter.add(:git_repos) { setcode { git_repos_count } }

#
# Find active capacity
# NOTE: based on count of git repos, not all gears
Facter.add(:active_capacity) do
  git_repos =  Facter.value(:git_repos).to_f
  max_active_apps = Facter.value(:max_active_apps).to_f
  active_capacity = ( (git_repos - stopped_app_count.to_f) / max_active_apps ) * 100
  setcode { active_capacity.to_s }
end

#
# Find capacity
#
Facter.add(:capacity) do
    git_repos =  Facter.value(:git_repos).to_f
    max_apps = Facter.value(:max_apps).to_f
    capacity = ( git_repos / max_apps ) * 100
    setcode { capacity.to_s }
end


#
# Get sshfp record
#
Facter.add(:sshfp) do
    setcode { %x[/usr/bin/ssh-keygen -r $(hostname) -f /etc/ssh/ssh_host_rsa_key]}
end

#
# List cartridges on the host
#   Convert from name-m.n.p to name-m.n
#   This is the *full* list.
#
Facter.add(:cart_list) do
    carts = []
    Dir.glob('/usr/libexec/openshift/cartridges/*/').each do |cart|
        cart = File.basename(cart).sub(/^(.*)-(\d+)\.(\d+)\.?.*$/, '\1-\2.\3')
        carts << cart unless cart.nil? || cart == "embedded"
    end
    setcode { carts.join('|') }
end

#
# List embedded cartridges on the host
#   Convert from name-m.n.p to name-m.n
#   This is the *full* list.
#
Facter.add(:embed_cart_list) do
    carts = []
    Dir.glob('/usr/libexec/openshift/cartridges/embedded/*/').each do |cart|
        cart = File.basename(cart).sub(/^(.*)-(\d+)\.(\d+)\.?.*$/, '\1-\2.\3')
        carts << cart unless cart.nil?
    end
    setcode { carts.join('|') }
end
