require 'rubygems'
require 'parseconfig'

def get_node_config_value(key, default)
  config_file = ParseConfig.new('/etc/openshift/node.conf')
  val = config_file[key]
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
  district_uuid = config_file['uuid'] ? config_file['uuid'] : 'NONE'
  district_active = config_file['active'] ? config_file['active'] == "true" : false
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
max_apps = nil
max_active_apps = nil
max_active_gears = nil
if File.exists?('/etc/openshift/resource_limits.conf')
  config_file = ParseConfig.new('/etc/openshift/resource_limits.conf')
  node_profile = config_file['node_profile'] || 'small'
  quota_blocks = config_file['quota_blocks'] || '1048576'
  quota_files = config_file['quota_files'] || '40000'
  # use max_{active_,}gears if set in resource limits, or fall back to old "apps" names
  max_active_gears = config_file['max_active_gears'] ||
    config_file['max_active_apps'] || '0'
end

Facter.add(:node_profile) { setcode { node_profile } }
Facter.add(:max_active_gears) { setcode { max_active_gears || '0' } }
Facter.add(:quota_blocks) { setcode { quota_blocks } }
Facter.add(:quota_files) { setcode { quota_files } }

#
# Count number of git repos and stopped apps
#
git_repos_count = 0
stopped_app_count = 0
gears_active_count = 0 # includes everything but idle and stopped
gears_total_count = 0
gears_idled_count = 0
gears_stopped_count = 0
gears_started_count = 0
gears_deploying_count = 0
gears_unknown_count = 0
Dir.glob("/var/lib/openshift/*").each do |app_dir|
  if File.directory?(app_dir) && !File.symlink?(app_dir)
    git_repos_count += Dir.glob(File.join(app_dir, "git/*.git")).count

    # note: only considered a gear if .state file is present. There are
    # other directories that aren't gears, e.g. ".httpd.d"
    Dir.glob(File.join(app_dir, %w{app-root runtime .state})).each do |file|
      gears_total_count += 1
      case File.read(file).chomp
        # expected values: building, deploying, started, idle, new, stopped, or unknown
      when 'idle'
          stopped_app_count += 1 # legacy
          gears_idled_count += 1
      when 'stopped'
          stopped_app_count += 1 # legacy
          gears_stopped_count += 1
      when 'started'
          gears_started_count += 1
      when *%w[new building deploying]
          gears_deploying_count += 1
      else # literally 'unknown' or something else
          gears_unknown_count += 1
      end
    end
  end
  # consider a gear active unless explicitly not
  gears_active_count = gears_total_count - gears_idled_count - gears_stopped_count
end

#
# Record gear-based counts and capacity
#
Facter.add(:gears_active_count) { setcode { gears_active_count } }
Facter.add(:gears_total_count) { setcode { gears_total_count } }
Facter.add(:gears_idle_count) { setcode { gears_idled_count } }
Facter.add(:gears_stopped_count) { setcode { gears_stopped_count } }
Facter.add(:gears_started_count) { setcode { gears_started_count } }
Facter.add(:gears_deploying_count) { setcode { gears_deploying_count } }
Facter.add(:gears_unknown_count) { setcode { gears_unknown_count } }
gears_usage_pct = begin gears_total_count * 100.0 / max_active_gears.to_f; rescue; 0.0; end
gears_active_usage_pct = begin gears_active_count * 100.0 / max_active_gears.to_f; rescue; 0.0; end
Facter.add(:gears_usage_pct) { setcode { gears_usage_pct } }
Facter.add(:gears_active_usage_pct) { setcode { gears_active_usage_pct } }

# Old "app" count, excludes some gears
Facter.add(:git_repos) { setcode { git_repos_count } }
#
# capacity and active capacity - deprecated but kept for backward compat
Facter.add(:capacity) { setcode { gears_usage_pct.to_s } }
Facter.add(:active_capacity) { setcode { gears_active_usage_pct.to_s } }

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
    carts = `oo-cartridge-list`.split
    # The first element is the text "Cartridges:"
    carts.shift
    carts.sort!
    setcode { carts.join('|') }
end
