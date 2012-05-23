require 'rubygems'
require 'parseconfig'

def get_node_config_value(key, default)
  config_file = ParseConfig.new('/etc/stickshift/stickshift-node.conf')
  val = config_file.get_value(key)
  return default if val.nil?
  val.gsub!(/\\:/,":") if not val.nil?
  val.gsub!(/[ \t]*#[^\n]*/,"") if not val.nil?
  val = val[1..-2] if not val.nil? and val.start_with? "\""
  val
end

#
# Count the number of git repos on this host
#
Facter.add(:git_repos) do
    git_repos_count = Dir.glob("/var/lib/stickshift/**/git/*.git").count
    setcode { git_repos_count }
end

#
# Setup the district
#
district_uuid = 'NONE'
district_active = false
if File.exists?('/etc/stickshift/district.conf')
  config_file = ParseConfig.new('/etc/stickshift/district.conf')
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
if File.exists?('/etc/stickshift/resource_limits.conf')
  config_file = ParseConfig.new('/etc/stickshift/resource_limits.conf')
  node_profile = config_file.get_value('node_profile') ? config_file.get_value('node_profile') : 'small'
  max_apps = config_file.get_value('max_apps') ? config_file.get_value('max_apps') : '0'
  max_active_apps = config_file.get_value('max_active_apps') ? config_file.get_value('max_active_apps') : '0'
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

#
# Find active capacity
#
Facter.add(:active_capacity) do
    git_repos =  Facter.value(:git_repos).to_f
    max_active_apps = Facter.value(:max_active_apps).to_f
    stopped_app_count = 0
    Dir.glob("/var/lib/stickshift/*").each { |app_dir|
        if File.directory?(app_dir) && !File.symlink?(app_dir)
            active = true
            Dir.glob(File.join(app_dir, '*', 'runtime', '.state')).each {|file|
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
    active_capacity = ( (git_repos - stopped_app_count) / max_active_apps ) * 100
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
    Dir.glob('/usr/libexec/stickshift/cartridges/*/').each do |cart|
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
    Dir.glob('/usr/libexec/stickshift/cartridges/embedded/*/').each do |cart|
        cart = File.basename(cart).sub(/^(.*)-(\d+)\.(\d+)\.?.*$/, '\1-\2.\3')
        carts << cart unless cart.nil?
    end
    setcode { carts.join('|') }
end
