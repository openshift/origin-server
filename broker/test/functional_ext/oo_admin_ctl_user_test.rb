ENV["TEST_NAME"] = "oo_admin_ctl_user_test"
require_relative '../test_helper'
require 'openshift-origin-controller'
require 'mocha/setup'
require 'tempfile'

class OoAdminCtlUserTest < ActionDispatch::IntegrationTest

  def generate_username
    "user_#{rand(1000000000)}"
  end

  def setup
    @existing_login = generate_username
    CloudUser.find_or_create_by_identity(nil, @existing_login)

    @non_existing_login = generate_username
    CloudUser.where(:login => @non_existing_login).delete

    tmpdir = File.join(Dir.tmpdir, "openshift")
    FileUtils.mkdir_p(tmpdir) unless File.exists?(tmpdir)
    @file = Tempfile.new('logins', tmpdir)
    @file.write(@non_existing_login)
    @file.write("\n")
    @file.write(@existing_login)
    @file.close
  end

  def teardown
    CloudUser.where(:login => @existing_login).delete
    CloudUser.where(:login => @non_existing_login).delete
    @file.unlink
  end

  def run_command(*args)
    result = `env "RAILS_ENV=test" oo-admin-ctl-user #{args.join(' ')} 2>&1`
    [result, $?.exitstatus]
  end

  def run_command_stderr(*args)
    result = `env "RAILS_ENV=test" oo-admin-ctl-user #{args.join(' ')} 2>&1 > /dev/null`
    [result, $?.exitstatus]
  end

  def test_quiet_help_mode
    o1,s1 = run_command '--help'
    o2,s2 = run_command '--help --quiet'

    assert_equal o1, o2
    assert_equal s1, s2
  end

  def test_quiet_mode
    o,s = run_command "-l #{@existing_login} --quiet"
    assert_equal "", o
    assert_equal 0, s
  end

  def test_existing_username
    o,s = run_command "-l #{@existing_login}"
    assert o =~ /User #{@existing_login}:/
    assert_equal 0, s
  end

  def test_non_existing_username
    o,s = run_command "-l #{@non_existing_login} --quiet"
    assert o =~ /User '#{@non_existing_login}' not found/, o
    assert_equal 5, s
  end

  def test_create_single
    assert_equal 0, CloudUser.where(:login => @non_existing_login).length
    o,s = run_command "-l #{@non_existing_login} --create"
    assert o =~ /User #{@non_existing_login}:/, o
    assert_equal 0, s
    assert_equal 1, CloudUser.where(:login => @non_existing_login).length
  end

  def test_list_mix_existing
    o,s = run_command "-f #{@file.path}"
    assert o =~ /User '#{@non_existing_login}' not found/, o
    assert o =~ /User #{@existing_login}:/, o
    assert_equal 5, s
  end

  def test_create_mix_existing
    assert users = CloudUser.in(:login => [@existing_login, @non_existing_login]).to_a
    assert_equal 1, users.length

    o,s = run_command "-f #{@file.path} --create --setmaxdomains 3 --setmaxgears 4 --setmaxtrackedstorage 5 --setmaxuntrackedstorage 6 --setconsumedgears 1 --allowsubaccounts true --allowplanupgrade false --allowprivatesslcertificates true --addgearsize medium --inheritgearsizes true --allowha true"
    assert o =~ /User #{@non_existing_login}:/, o
    assert o =~ /User #{@existing_login}:/, o
    assert_equal 0, s

    assert users = CloudUser.in(:login => [@existing_login, @non_existing_login]).to_a

    assert_equal 2, users.length
    assert_equal [3],                   users.map(&:max_domains                     ).uniq, users.inspect
    assert_equal [4],                   users.map(&:max_gears                       ).uniq, users.inspect
    assert_equal [5],                   users.map(&:max_tracked_additional_storage  ).uniq, users.inspect
    assert_equal [6],                   users.map(&:max_untracked_additional_storage).uniq, users.inspect
    assert_equal [1],                   users.map(&:consumed_gears                  ).uniq, users.inspect
    assert_equal [true],                users.map(&:subaccounts                     ).uniq, users.inspect
    assert_equal [false],               users.map(&:plan_upgrade_enabled            ).uniq, users.inspect
    assert_equal [true],                users.map(&:private_ssl_certificates        ).uniq, users.inspect
    assert_equal [['small', 'medium']], users.map(&:allowed_gear_sizes              ).uniq, users.inspect
    assert_equal [true],                users.map(&:ha                              ).uniq, users.inspect
  end

  def test_set_remove_usage_account_id
    test_usageaccountid = "12345"

    o,s = run_command "-f #{@file.path} --create --setusageaccountid #{test_usageaccountid}"
    user = CloudUser.where(:login => @existing_login).first
    assert_equal 0, s
    assert_equal test_usageaccountid, user.usage_account_id

    o,s = run_command "-f #{@file.path} --removeusageaccountid"
    user = CloudUser.where(:login => @existing_login).first
    assert_equal 0, s
    assert_equal nil, user.usage_account_id

    o,s = run_command "-f #{@file.path} --setusageaccountid #{test_usageaccountid} --removeusageaccountid"
    assert_equal 255, s
  end

end
