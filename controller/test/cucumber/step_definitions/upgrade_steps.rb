def upgrade_gear(name, login, gear_uuid)
  current_version = 'expected'
  cmd = "oo-admin-upgrade upgrade-gear --app-name='#{@app.name}' --login='#{@app.login}' --upgrade-gear=#{gear_uuid} --version='#{current_version}'"
  $logger.info("Upgrading with command: #{cmd}")
  output = `#{cmd}`
  $logger.info("Upgrade output: #{output}")
  assert_equal 0, $?.exitstatus
end

Then /^the upgrade metadata will be cleaned up$/ do
  assert_metadata_cleaned(@app)
end

Then /^the upgrade metadata will be cleaned up in (.+)$/ do |app_name|
  app = @test_apps_hash[app_name]
  assert_metadata_cleaned(app)
end

def assert_metadata_cleaned(app)
  assert Dir.glob(File.join($home_root, app.uid, 'runtime', '.upgrade*')).empty?
  refute_file_exist File.join($home_root, app.uid, 'app-root', 'runtime', '.preupgrade_state')
end

Then /^no unprocessed ERB templates should exist$/ do
  assert_unprocessed_erbs(true, @app)
end

Then /^(no )?unprocessed ERB templates should exist in (.+)$/ do |negate, app_name|
  app = @test_apps_hash[app_name]
  assert_unprocessed_erbs(negate, app)
end

def assert_unprocessed_erbs(negate, app)
  glob = Dir.glob(File.join($home_root, app.uid, '**', '**', '*.erb'))

  if negate
    assert glob.empty?
  else
    assert !glob.empty?
  end
end

Given /^the ([\d\.]+) version of the ([^ ]+)\-([\d\.]+) cartridge is installed$/ do |cartridge_version, cart_name, software_version|
  # Try to discover the packaged version of manifest.yml using rpm
  cart_manifest_from_package = %x(/bin/rpm -ql openshift-origin-cartridge-#{cart_name} | /bin/grep 'manifest.yml$').strip
  # Fall back to current RPM installation path
  if cart_manifest_from_package.empty?
    cart_manifest_from_package = "/usr/libexec/openshift/cartridges/#{cart_name}/metadata/manifest.yml"
  end

  rpm_manifest = YAML.load_file(cart_manifest_from_package)

  cart_repo = OpenShift::Runtime::CartridgeRepository.instance

  # This might be useful info - stash it
  @packaged_carts ||= {}
  @packaged_carts[cart_name] ||= {}
  @packaged_carts[cart_name]['Version'] = rpm_manifest['Version']
  @packaged_carts[cart_name]['Cartridge-Version'] = rpm_manifest['Cartridge-Version']

  # Make sure the package we've found provides the version of the
  # cartridge component we're looking for
  rpm_version = rpm_manifest['Version']
  rpm_cartridge_version = rpm_manifest['Cartridge-Version']

  assert software_version == rpm_version
  assert cartridge_version == rpm_cartridge_version

  # Ensure that the specified (cart_name, version, cartridge_version) is available and the latest
  # in the repository
  assert cart_repo.latest_cartridge_version?('redhat', cart_name, rpm_version, rpm_cartridge_version), "(redhat,#{cart_name},#{software_version},#{cartridge_version}) must be the latest in the repository"
end

Given /^a compatible version of the ([^ ]+)\-([\d\.]+) cartridge$/ do |cart_name, component_version|
  current_manifest = prepare_cart_for_rewrite(cart_name, component_version)
  create_upgrade_script(@upgrade_script_path)

  rewrite_and_install(current_manifest, @manifest_path) do |manifest, current_version|
    manifest['Compatible-Versions'] = [ current_version ]
  end
end

Given /^an incompatible version of the ([^ ]+)\-([\d\.]+) cartridge$/ do |cart_name, component_version|
  current_manifest = prepare_cart_for_rewrite(cart_name, component_version)
  create_upgrade_script(@upgrade_script_path)

  new_endpoint = { 'Private-IP-Name' => 'EXAMPLE_IP1', 'Private-Port-Name' => 'EXAMPLE_PUBLIC_PORT4', 'Private-Port' => 8083 }

  rewrite_and_install(current_manifest, @manifest_path) do |manifest, current_version|
    manifest['Endpoints'] << new_endpoint
  end
end

Then /^a new port will be exposed$/ do
  port_env_file = File.join($home_root, @app.uid, '.env', 'OPENSHIFT_MOCK_EXAMPLE_PUBLIC_PORT4')
  assert_file_exist port_env_file
end

Given /^a rigged version of the ([^ ]+)\-([\d\.]+) cartridge set to fail (\d) times$/ do |cart_name, component_version, max_failures|
  current_manifest = prepare_cart_for_rewrite(cart_name, component_version)
  create_rigged_upgrade_script(@upgrade_script_path, max_failures)

  rewrite_and_install(current_manifest, @manifest_path)
end

Given /^a compatible version of the ([^ ]+)\-([\d\.]+) cartridge with different software version$/ do |cart_name, component_version|
  current_manifest = prepare_cart_for_rewrite(cart_name, component_version)
  create_upgrade_script(@upgrade_script_path)

  rewrite_and_install(current_manifest, @manifest_path) do |manifest, current_version|
    manifest['Compatible-Versions'] = [ current_version ]
    manifest['Version'] = '99'
  end
end

Given /^an incompatible version of the ([^ ]+)\-([\d\.]+) cartridge with different software version$/ do |cart_name, component_version|
  current_manifest = prepare_cart_for_rewrite(cart_name, component_version)
  create_upgrade_script(@upgrade_script_path)

  rewrite_and_install(current_manifest, @manifest_path) do |manifest, current_version|
    manifest['Version'] = '99'
  end
end

def prepare_cart_for_rewrite(cart_name, component_version)
  @cartridge_path       = File.join('/usr/libexec/openshift/cartridges', cart_name)
  @manifest_path        = File.join(@cartridge_path, 'metadata', 'manifest.yml')
  @manifest_backup_path = @manifest_path + '~'
  @upgrade_script_path  = File.join(@cartridge_path, 'bin', 'upgrade')
  @hooks_path           = File.join(@cartridge_path, 'hooks')

  FileUtils.copy(@manifest_path, @manifest_backup_path)
  cart_repo = OpenShift::Runtime::CartridgeRepository.instance
  cart_repo.select('redhat', cart_name, component_version)
end

def create_upgrade_script(target)
  upgrade_script = <<-EOF
#!/bin/bash

source $OPENSHIFT_CARTRIDGE_SDK_BASH
source $OPENSHIFT_MOCK_DIR/mock.conf

touch $MOCK_STATE/upgrade_invoked
EOF

  IO.write(target, upgrade_script, 0, mode: 'w', perm: 0744)
end

def create_rigged_upgrade_script(target, max_failures = 1)
  upgrade_script = <<-EOF
#!/bin/bash

source $OPENSHIFT_CARTRIDGE_SDK_BASH
source $OPENSHIFT_MOCK_DIR/mock.conf

version=$1
current_software_version=$2
next_software_version=$3
max_failures=#{max_failures}

if [ -f $MOCK_STATE/upgrade_script_failure_count ]; then
  num_failures=$(<$MOCK_STATE/upgrade_script_failure_count)
else
  num_failures=0
fi

echo "version: $version, max_failures: $max_failures, num_failures=$num_failures"

if [ "$version" == "0.1" ]; then
  if [ $num_failures -lt $max_failures ]; then
    echo -n $(expr $num_failures + 1) > $MOCK_STATE/upgrade_script_failure_count
    echo "rigged upgrade script is failing"
    exit 1
  fi
fi

touch $MOCK_STATE/upgrade_invoked

exit 0
EOF

  IO.write(target, upgrade_script, 0, mode: 'w', perm: 0744)
end

def rewrite_and_install(current_manifest, path, new_hooks = nil)
  cart_name = current_manifest.name
  manifest = YAML.load_file(@manifest_path)

  current_version = current_manifest.cartridge_version
  current_version =~ /(\d+)$/
  current_minor_version = $1.to_i
  next_version = current_version.sub(/\d+$/, (current_minor_version + 1).to_s)

  manifest['Cartridge-Version'] = next_version

  yield manifest, current_version if block_given?
  if new_hooks
    add_new_hooks @hooks_path, new_hooks
  end

  IO.write(@manifest_path, manifest.to_yaml)
  if @app
    IO.write(File.join($home_root, @app.uid, %W(app-root data #{cart_name}_test_version)), next_version)
  end

  assert_successful_install next_version, current_manifest
end

def add_new_hooks(path, new_hooks)
  FileUtils.mkpath(path) unless File.exist?(path)

  new_hooks.each do |hook|
    hook_path = File.join(path, hook[:name])
    n = IO.write(hook_path, hook[:content], 0, mode: 'w', perm: 0755)
    $logger.info "Created hook: #{hook_path}(#{n})"
  end
end

def assert_successful_install(next_version, current_manifest)
  OpenShift::Runtime::CartridgeRepository.instance.install(@cartridge_path)
  observed_latest_version = OpenShift::Runtime::CartridgeRepository.instance.
      select('redhat', current_manifest.name, current_manifest.version).
      cartridge_version

  $logger.info "Observed latest version: #{observed_latest_version}"

  assert_equal next_version, observed_latest_version

  if File.exists?("/etc/fedora-release")
    %x(service mcollective restart)
  else
    %x(service ruby193-mcollective restart)
  end

  mcol_output = `oo-admin-cartridge --list | grep -e "mock,.*#{current_manifest.version}"`

  assert_equal 0, $?, "Couldn't find new cartridge in oo-admin-cartridge output: #{mcol_output}"

  sleep 5
end

Then /^the ([^ ]+) cartridge version should (not )?be updated$/ do |cart_name, negate|
  assert_cart_version_updated(cart_name, @app, negate)
end

Then /^the ([^ ]+) cartridge version should (not )?be updated in (.+)$/ do |cart_name, negate, app_name|
  app = @test_apps_hash[app_name]
  assert_cart_version_updated(cart_name, app, negate)
end

def assert_cart_version_updated(cart_name, app, negate=false)
  new_version = IO.read(File.join($home_root, @app.uid, %W(app-root data #{cart_name}_test_version))).chomp

  ident_path                 = Dir.glob(File.join($home_root, app.uid, %W(#{cart_name} env OPENSHIFT_*_IDENT))).first
  ident                      = IO.read(ident_path)
  _, _, _, cartridge_version = OpenShift::Runtime::Manifest.parse_ident(ident)

  if negate
    assert_not_equal new_version, cartridge_version
  else
    assert_equal new_version, cartridge_version
  end
end

Then /^the ([^ ]+) cartridge software version should be updated$/ do |cart_name|
  new_version = '99'
  ident_path                = Dir.glob(File.join($home_root, @app.uid, %W(#{cart_name} env OPENSHIFT_*_IDENT))).first
  ident                     = IO.read(ident_path)
  _, _, software_version, _ = OpenShift::Runtime::Manifest.parse_ident(ident)

  assert_equal new_version, software_version
end

When /^the ([^ ]+) invocation markers are cleared$/ do |cartridge_name|
  clear_invocation_markers(cartridge_name, @app)
end

When /^the ([^ ]+) invocation markers are cleared in (.+)$/ do |cartridge_name, app_name|
  app = @test_apps_hash[app_name]
  clear_invocation_markers(cartridge_name, app)
end

def clear_invocation_markers(cartridge_name, app)
  state_dir_name = ".#{cartridge_name.sub('-', '_')}_cartridge_state"
  Dir.glob(File.join($home_root, app.uid, 'app-root', 'data', state_dir_name, '*')).each { |x|
    FileUtils.rm_f(x) unless x.end_with?('_process')
  }
end

When /^the application is upgraded to the new cartridge versions$/ do
  upgrade_gear(@app.name, @app.login, @app.uid)
end

Then /^the invocation markers from an? (compatible|incompatible) upgrade should exist$/ do |type|
  assert_invocation_markers_exist(type, false, @app)
end

Then /^the invocation markers from an? (compatible|incompatible) upgrade should (not )?exist in (.+)$/ do |type, negate, app_name|
  app = @test_apps_hash[app_name]
  assert_invocation_markers_exist(type, negate, app)
end

def assert_invocation_markers_exist(type, negate, app)
  should_exist_markers = case type
  when 'compatible'
    %w(upgrade_invoked)
  when 'incompatible'
    # upgrade_invoked is not in this list because the mock cartridge setup clears the state directory
    %w(setup_called setup_succeed control_start control_status)
  end

  should_not_exist_markers = case type
  when 'compatible'
    %w(setup_called control_start)
  when 'incompatible'
    # The control_stop marker is deleted during the mock cartridge setup,
    # so we expect it _not_ to exist after an incompatible upgrade.
    %w(setup_failure control_stop)
  end

  if negate
    all_markers_exist = true

    should_exist_markers.each do |marker|
      marker_file = File.join($home_root, app.uid, 'app-root', 'data', '.mock_cartridge_state', marker)
      if !File.exists? marker_file
        all_markers_exist = false
        break
      end
    end

    assert !all_markers_exist
  else
    should_exist_markers.each do |marker|
      marker_file = File.join($home_root, app.uid, 'app-root', 'data', '.mock_cartridge_state', marker)
      assert_file_exist marker_file
    end

    should_not_exist_markers.each do |marker|
      marker_file = File.join($home_root, app.uid, 'app-root', 'data', '.mock_cartridge_state', marker)
      refute_file_exist marker_file
    end
  end
end

Given /^a gear level upgrade extension exists$/ do
  gear_upgrade_content = <<-EOF
module OpenShift
  class GearUpgradeExtension
    def self.version
      'expected'
    end

    def initialize(upgrader)
      @uuid = upgrader.uuid
      @gear_home = upgrader.gear_home
    end

    def pre_upgrade(progress)
      progress.log("Creating pre-upgrade marker")
      touch_marker('pre')
    end

    def pre_cartridge_upgrade(progress, itinerary)
      progress.log("Creating pre-cartridge-upgrade marker")
      touch_marker('pre_cartridge')
    end

    def post_cartridge_upgrade(progress, itinerary)
      progress.log("Creating post-cartridge-upgrade marker")
      touch_marker('post_cartridge')
    end

    def post_upgrade(progress)
      progress.log("Creating post-upgrade marker")
      touch_marker('post')
    end

    def touch_marker(name)
      marker_name = ".gear_upgrade_\#{name}"
      marker_path = File.join(@gear_home, 'app-root', 'data', marker_name)
      FileUtils.touch(marker_path)
    end
  end
end
EOF

  IO.write('/tmp/gear_upgrade.rb', gear_upgrade_content)
  `echo '\nGEAR_UPGRADE_EXTENSION=/tmp/gear_upgrade' >> /etc/openshift/node.conf`
end

Given /^a gear level upgrade extension to map the updated software version exists$/ do
  gear_upgrade_content = <<-EOF
module OpenShift
  class GearUpgradeExtension

    VERSION_MAP = {
      'mock-0.1'      => '99',
    }

    def self.version
      'expected'
    end

    def initialize(upgrader)
      @uuid = upgrader.uuid
      @gear_home = upgrader.gear_home
    end

    def pre_upgrade(progress)
      progress.log("Creating pre-upgrade marker")
      touch_marker('pre')
    end

    def pre_cartridge_upgrade(progress, itinerary)
      progress.log("Creating pre-cartridge-upgrade marker")
      touch_marker('pre_cartridge')
    end

    def post_cartridge_upgrade(progress, itinerary)
      progress.log("Creating post-cartridge-upgrade marker")
      touch_marker('post_cartridge')
    end

    def post_upgrade(progress)
      progress.log("Creating post-upgrade marker")
      touch_marker('post')
    end

    def touch_marker(name)
      marker_name = ".gear_upgrade_\#{name}"
      marker_path = File.join(@gear_home, 'app-root', 'data', marker_name)
      FileUtils.touch(marker_path)
    end

    def map_ident(progress, ident)
      vendor, name, version, cartridge_version = OpenShift::Runtime::Manifest.parse_ident(ident)
      progress.log "In map_ident; parse_ident output - vendor: \#{vendor}, name: \#{name}, version: \#{version}, cartridge_version: \#{cartridge_version}"
      name_version = "\#{name}-\#{version}"
      progress.log "Mapping version \#{version} to \#{VERSION_MAP[name_version]} for cartridge \#{name}" if VERSION_MAP[name_version]
      version = VERSION_MAP[name_version] || version
      return vendor, name, version, cartridge_version
    end
  end
end
EOF
  IO.write('/tmp/gear_upgrade.rb', gear_upgrade_content)
  `echo '\nGEAR_UPGRADE_EXTENSION=/tmp/gear_upgrade' >> /etc/openshift/node.conf`
end

Then /^the invocation markers from the gear upgrade should exist$/ do
  assert_file_exist File.join($home_root, @app.uid, %w(app-root data .gear_upgrade_pre))
  assert_file_exist File.join($home_root, @app.uid, %w(app-root data .gear_upgrade_pre_cartridge))
  assert_file_exist File.join($home_root, @app.uid, %w(app-root data .gear_upgrade_post_cartridge))
  assert_file_exist File.join($home_root, @app.uid, %w(app-root data .gear_upgrade_post))
end

When /^the gears on the node are upgraded with oo-admin-upgrade?$/ do
  uuid_whitelist = @test_apps_hash.values.collect {|app| app.uid}

  upgrade_cmd = "oo-admin-upgrade upgrade-node --version expected --gear-whitelist #{uuid_whitelist.join(' ')}"

  $logger.info("Executing upgrade cmd: #{upgrade_cmd}")
  output = `#{upgrade_cmd}`

  $logger.info("Upgrade output: #{output}")
  assert_equal 0, $?.exitstatus
end

Then /^existing oo-admin-upgrade output is archived$/ do
  output = `oo-admin-upgrade archive`
  assert_equal 0, $?.exitstatus
  $logger.info("Archive output: #{output}")
end
