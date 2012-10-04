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
Facter.add(:district_uuid) do
  setcode { district_uuid }
end
Facter.add(:district_active) do
  setcode { district_active }
end

#
# Pull public_ip and public_hostname out of the node_data config
#
public_ip = get_node_config_value("PUBLIC_IP", "UNKNOWN").gsub(/['"]/,"")
public_hostname = get_node_config_value("PUBLIC_HOSTNAME", "UNKNOWN").gsub(/['"]/,"")
Facter.add(:public_ip) do
  setcode { public_ip }
end
Facter.add(:public_hostname) do
  setcode { public_hostname }
end

#
# Find node_profile, max_apps, max_active_apps
#
node_profile = 'small'
max_apps = '0'
max_active_apps = '0'
if File.exists?('/etc/openshift/resource_limits.conf')
  config_file = ParseConfig.new('/etc/openshift/resource_limits.conf')
  node_profile = config_file.get_value('node_profile') ? config_file.get_value('node_profile') : 'small'
  max_apps = config_file.get_value('max_apps') ? config_file.get_value('max_apps') : '0'
  max_active_apps = config_file.get_value('max_active_apps') ? config_file.get_value('max_active_apps') : '0'
  quota_blocks = config_file.get_value('quota_blocks') ? config_file.get_value('quota_blocks') : '1048576'
  quota_files = config_file.get_value('quota_files') ? config_file.get_value('quota_files') : '40000'
end

Facter.add(:node_profile) do
  setcode { node_profile }
end

Facter.add(:max_apps) do
  setcode { max_apps }
end

Facter.add(:max_active_apps) do
  setcode { max_active_apps }
end

Facter.add(:quota_blocks) do
  setcode { quota_blocks }
end

Facter.add(:quota_files) do
  setcode { quota_files }
end

#
# Count number of git repos and stopped apps
#
git_repos_count = 0
stopped_app_count = 0
Dir.glob("/var/lib/openshift/*").each { |app_dir|
  if File.directory?(app_dir) && !File.symlink?(app_dir)
    git_repos_count += Dir.glob(File.join(app_dir, "git/*.git")).count

    active = true
    Dir.glob(File.join(app_dir, 'app-root', 'runtime', '.state')).each {|file|
      state = File.read(file).chomp
      if 'idle' == state || 'stopped' == state
        active = false
      end
    }
    if not active
      stopped_app_count += 1
    end
  end
}

Facter.add(:git_repos) do
  setcode { git_repos_count }
end

#
# Find active capacity
#
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
