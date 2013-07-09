def upgrade_gear(name, login, gear_uuid)
  current_version = '2.0.29' #OpenShiftMigration.current_version
  output = `oo-admin-upgrade --app-name #{@app.name} --login #{@app.login} --upgrade-gear #{gear_uuid} --version #{current_version}`
  $logger.info("Upgrade output: #{output}")
  assert_equal 0, $?.exitstatus
end

Then /^the upgrade metadata will be cleaned up$/ do 
  assert Dir.glob(File.join($home_root, @app.uid, 'data', '.upgrade*')).empty?
  assert_file_not_exists File.join($home_root, @app.uid, 'app-root', 'runtime', '.preupgrade_state')
end

Then /^no unprocessed ERB templates should exist$/ do
  assert Dir.glob(File.join($home_root, @app.uid, '**', '**', '*.erb')).empty?
end

# TODO: eliminate dependency on 0.0.1 version being hardcoded

Given /^the expected version of the mock cartridge is installed$/ do
  cart_repo = OpenShift::Runtime::CartridgeRepository.instance
  assert cart_repo.exist?('mock', '0.0.1', '0.1'), 'expected mock version must exist'
end

Given /^a compatible version of the mock cartridge$/ do
  tmp_cart_src = '/tmp/mock-cucumber-rewrite/compat'
  current_manifest = prepare_mock_for_rewrite(tmp_cart_src)

  rewrite_and_install(current_manifest, tmp_cart_src) do |manifest, current_version|
    manifest['Compatible-Versions'] = [ current_version ]
  end
end

Given /^an incompatible version of the mock cartridge$/ do
  tmp_cart_src = '/tmp/mock-cucumber-rewrite/incompat'
  current_manifest = prepare_mock_for_rewrite(tmp_cart_src)

  rewrite_and_install(current_manifest, tmp_cart_src)
end

def prepare_mock_for_rewrite(target)
  cart_repo = OpenShift::Runtime::CartridgeRepository.instance
  cartridge = cart_repo.select('mock', '0.1')

  FileUtils.rm_rf target
  FileUtils.mkpath target

  %x(shopt -s dotglob; cp -ad #{cartridge.repository_path}/* #{target})

  cartridge
end

def rewrite_and_install(current_manifest, tmp_cart_src)
  cart_manifest = File.join(tmp_cart_src, %w(metadata manifest.yml))

  current_version = current_manifest.cartridge_version
  current_version =~ /(\d+)$/
  current_minor_version = $1.to_i
  next_version = current_version.sub(/\d+$/, (current_minor_version + 1).to_s)

  manifest = YAML.load_file(cart_manifest)
  manifest['Cartridge-Version'] = next_version

  yield manifest, current_version if block_given?

  IO.write(cart_manifest, manifest.to_yaml)
  IO.write(File.join($home_root, @app.uid, %w(app-root data mock_test_version)), next_version)

  assert_successful_install tmp_cart_src, next_version
end

def assert_successful_install(tmp_cart_src, next_version)
  OpenShift::Runtime::CartridgeRepository.instance.install(tmp_cart_src)
  observed_latest_version = OpenShift::Runtime::CartridgeRepository.instance.select('mock', '0.1').cartridge_version

  $logger.info "Observed latest version: #{observed_latest_version}"

  assert_equal next_version, observed_latest_version

  %x(pkill -USR1 -f /usr/sbin/mcollectived)
end

Then /^the mock cartridge version should be updated$/ do
  new_version = IO.read(File.join($home_root, @app.uid, %w(app-root data mock_test_version))).chomp

  ident_path                 = Dir.glob(File.join($home_root, @app.uid, %w(mock env OPENSHIFT_*_IDENT))).first
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
    %w(control_status)
  when 'incompatible'
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
    assert_file_exists marker_file
  end

  should_not_exist_markers.each do |marker|
    marker_file = File.join($home_root, @app.uid, 'app-root', 'data', '.mock_cartridge_state', marker)
    assert_file_not_exists marker_file
  end    
end

Given /^a gear level upgrade extension exists$/ do
  gear_upgrade_content = <<-EOF
module OpenShift
  class GearUpgradeExtension
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
  assert_file_exists File.join($home_root, @app.uid, %w(app-root data .gear_upgrade_pre))
  assert_file_exists File.join($home_root, @app.uid, %w(app-root data .gear_upgrade_post))
end
