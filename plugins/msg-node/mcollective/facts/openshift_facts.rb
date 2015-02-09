require 'rubygems'
require 'parseconfig'
require 'openshift-origin-node/model/node'

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
  district_first_uid = config_file['first_uid'] ? config_file['first_uid'] : 1000
  district_max_uid = config_file['max_uid'] ? config_file['max_uid'] : 6999
end
Facter.add(:district_uuid) { setcode { district_uuid } }
Facter.add(:district_active) { setcode { district_active } }
Facter.add(:district_first_uid) { setcode { district_first_uid } }
Facter.add(:district_max_uid) { setcode { district_max_uid } }

#
# Pull public_ip and public_hostname out of the node_data config
#
public_ip = get_node_config_value("PUBLIC_IP", "UNKNOWN").gsub(/['"]/,"")
public_hostname = get_node_config_value("PUBLIC_HOSTNAME", "UNKNOWN").gsub(/['"]/,"")
Facter.add(:public_ip) { setcode { public_ip } }
Facter.add(:public_hostname) { setcode { public_hostname } }

#
# public_ip assigned to the config specified NIC (default eth0)
#
public_nic = get_node_config_value("EXTERNAL_ETH_DEV", "eth0").gsub(/['"]/,"")
host_public_ip = `/sbin/ifconfig #{public_nic} | /bin/grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`.chomp
Facter.add(:host_ip) { setcode { host_public_ip } }

#
# Pull node_utilization data from node model
#
results = OpenShift::Runtime::Node.node_utilization

Facter.add(:node_profile) { setcode { results['node_profile'] } }
Facter.add(:max_active_gears) { setcode { results['max_active_gears'] || '0' } }
Facter.add(:no_overcommit_active) { setcode { results['no_overcommit_active'] || false } }
Facter.add(:quota_blocks) { setcode { results['quota_blocks'] } }
Facter.add(:quota_files) { setcode { results['quota_files'] } }
Facter.add(:gears_active_count) { setcode { results['gears_active_count'] } }
Facter.add(:gears_total_count) { setcode { results['gears_total_count'] } }
Facter.add(:gears_idle_count) { setcode { results['gears_idled_count'] } }
Facter.add(:gears_stopped_count) { setcode { results['gears_stopped_count'] } }
Facter.add(:gears_started_count) { setcode { results['gears_started_count'] } }
Facter.add(:gears_deploying_count) { setcode { results['gears_deploying_count'] } }
Facter.add(:gears_unknown_count) { setcode { results['gears_unknown_count'] } }
Facter.add(:gears_usage_pct) { setcode { results['gears_usage_pct'] } }
Facter.add(:gears_active_usage_pct) { setcode { results['gears_active_usage_pct'] } }

# Old "app" count, excludes some gears
Facter.add(:git_repos) { setcode { results['git_repos_count'] } }

# capacity and active capacity - deprecated but kept for backward compat
Facter.add(:capacity) { setcode { results['capacity'] } }
Facter.add(:active_capacity) { setcode { results['active_capacity'] } }

#
# Get sshfp record
#
Facter.add(:sshfp) do
    setcode { %x[/usr/bin/ssh-keygen -r $(hostname) -f /etc/ssh/ssh_host_rsa_key]}
end
