def upgrade_gear(name, login, gear_uuid)
  current_version = 'expected'
  output = `oo-admin-upgrade --app-name #{@app.name} --login #{@app.login} --upgrade-gear #{gear_uuid} --version #{current_version}`
  $logger.info("Upgrade output: #{output}")
  assert_equal 0, $?.exitstatus
end

Then /^the upgrade metadata will be cleaned up$/ do 
  assert Dir.glob(File.join($home_root, @app.uid, 'runtime', '.upgrade*')).empty?
  refute_file_exist File.join($home_root, @app.uid, 'app-root', 'runtime', '.preupgrade_state')
end

Then /^no unprocessed ERB templates should exist$/ do
  assert Dir.glob(File.join($home_root, @app.uid, '**', '**', '*.erb')).empty?
end

Given /^the expected version of the ([^ ]+)\-([\d\.]+) cartridge is installed$/ do |cart_name, component_version|
  # Try to discover the packaged version of manifest.yml using rpm
  cart_manifest_from_package = %x(/bin/rpm -ql openshift-origin-cartridge-#{cart_name} | /bin/grep 'manifest.yml$').strip
  # Fall back to semi-hardcoded "where it should be" path
  if cart_manifest_from_package.empty?
    cart_manifest_from_package = "/usr/libexec/openshift/cartridges/#{cart_name}/metadata/manifest.yml" 
  end
  manifest_from_package = YAML.load_file(cart_manifest_from_package)

  cart_repo = OpenShift::Runtime::CartridgeRepository.instance

  # This might be useful info - stash it
  @packaged_carts ||= {}
  @packaged_carts[cart_name] ||= {}
  @packaged_carts[cart_name]['Version'] = manifest_from_package['Version']
  @packaged_carts[cart_name]['Cartridge-Version'] = manifest_from_package['Cartridge-Version']

  # Make sure the package we've found provides the version of the
  # cartridge component we're looking for
  assert component_version = manifest_from_package['Version']

  assert cart_repo.exist?(cart_name, manifest_from_package['Cartridge-Version'], manifest_from_package['Version']), "expected #{cart_name} version must exist"
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

  rewrite_and_install(current_manifest, @manifest_path)
end

def prepare_cart_for_rewrite(cart_name, component_version)
  @cartridge_path       = File.join('/usr/libexec/openshift/cartridges', cart_name)
  @manifest_path        = File.join(@cartridge_path, 'metadata', 'manifest.yml')
  @manifest_backup_path = @manifest_path + '~'
  @upgrade_script_path  = File.join(@cartridge_path, 'bin', 'upgrade')
  @hooks_path           = File.join(@cartridge_path, 'hooks')

  FileUtils.copy(@manifest_path, @manifest_backup_path)
  cart_repo = OpenShift::Runtime::CartridgeRepository.instance
  cart_repo.select(cart_name, component_version)
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
      select(current_manifest.name, current_manifest.version).
      cartridge_version

  $logger.info "Observed latest version: #{observed_latest_version}"

  assert_equal next_version, observed_latest_version

  %x(service mcollective restart)

  sleep 5
end

Then /^the ([^ ]+) cartridge version should be updated$/ do |cart_name|
  new_version = IO.read(File.join($home_root, @app.uid, %W(app-root data #{cart_name}_test_version))).chomp

  ident_path                 = Dir.glob(File.join($home_root, @app.uid, %W(#{cart_name} env OPENSHIFT_*_IDENT))).first
  ident                      = IO.read(ident_path)
  _, _, _, cartridge_version = OpenShift::Runtime::Manifest.parse_ident(ident)

  assert_equal new_version, cartridge_version
end

When /^the ([^ ]+) invocation markers are cleared$/ do |cartridge_name|
  state_dir_name = ".#{cartridge_name.sub('-', '_')}_cartridge_state"
  Dir.glob(File.join($home_root, @app.uid, 'app-root', 'data', state_dir_name, '*')).each { |x| 
    FileUtils.rm_f(x) unless x.end_with?('_process')
  }
end

When /^the application is upgraded to the new cartridge versions$/ do
  upgrade_gear(@app.name, @app.login, @app.uid)
end

Then /^the invocation markers from an? (compatible|incompatible) upgrade should exist$/ do |type|
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

  should_exist_markers.each do |marker|
    marker_file = File.join($home_root, @app.uid, 'app-root', 'data', '.mock_cartridge_state', marker)
    assert_file_exist marker_file
  end

  should_not_exist_markers.each do |marker|
    marker_file = File.join($home_root, @app.uid, 'app-root', 'data', '.mock_cartridge_state', marker)
    refute_file_exist marker_file
  end    
end

Given /^a gear level upgrade extension exists$/ do
  gear_upgrade_content = <<-EOF
module OpenShift
  class GearUpgradeExtension
    def self.version
      'expected'
    end

    def initialize(uuid, gear_home)
      @uuid = uuid
      @gear_home = gear_home
    end

    def pre_upgrade(progress)
      progress.log("Creating pre-upgrade marker")
      touch_marker('pre')
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
  `echo 'GEAR_UPGRADE_EXTENSION=/tmp/gear_upgrade' >> /etc/openshift/node.conf`
end

Then /^the invocation markers from the gear upgrade should exist$/ do
  assert_file_exist File.join($home_root, @app.uid, %w(app-root data .gear_upgrade_pre))
  assert_file_exist File.join($home_root, @app.uid, %w(app-root data .gear_upgrade_post))
end
