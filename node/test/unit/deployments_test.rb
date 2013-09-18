#!/usr/bin/env oo-ruby
#--
# Copyright 2013 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

require_relative '../test_helper'
require 'fileutils'

class DeploymentsTest < OpenShift::NodeTestCase
  def setup
    # Set up the container
    @gear_uuid = "5502"
    @user_uid  = "5502"
    @app_name  = 'DeploymentsTestCase'
    @gear_name = @app_name
    @namespace = 'jwh201204301647'
    @gear_ip   = "127.0.0.1"

    @test_dir = File.join('/tmp', time_to_s(Time.now))

    Etc.stubs(:getpwnam).returns(
      OpenStruct.new(
        uid: @user_uid.to_i,
        gid: @user_uid.to_i,
        gecos: "OpenShift guest",
        dir: @test_dir
      )
    )

    @container = OpenShift::Runtime::ApplicationContainer.new(@gear_uuid, @gear_uuid, @user_uid, @app_name, @gear_uuid, @namespace, nil, nil, nil)
    FileUtils.mkdir_p File.join(@test_dir, 'app-deployments', 'by-id')
    @runtime_dir = File.join(@test_dir, 'app-root', 'runtime')
    FileUtils.mkdir_p @runtime_dir
  end

  def teardown
    unless ENV['PRESERVE']
      FileUtils.rm_rf @test_dir
    end
  end

  def create_deployment_dir(deployment_datetime)
    %w(repo dependencies).each {|d| FileUtils.mkdir_p File.join(@test_dir, 'app-deployments', deployment_datetime, d)}
  end

  def time_to_s(time)
    time.strftime("%Y-%m-%d_%H-%M-%S.%L")
  end

  def test_all_deployments_empty
    assert_empty @container.all_deployments
  end

  def test_all_deployments_populated_and_sorted
    %w(ccc bbb aaa).each { |d| FileUtils.mkdir_p File.join(@test_dir, 'app-deployments', d)}
    expected = %w(aaa bbb ccc).map { |d| File.join(@test_dir, 'app-deployments', d)}
    all = @container.all_deployments

    assert_equal expected, all
  end

  def test_latest_deployment_datetime
    deployment_datetime1 = '2013-08-16_13-36-36.880'
    deployment_datetime2 = '2013-08-16_14-36-36.880'
    deployment_datetime3 = '2013-08-16_14-36-36.881'
    [deployment_datetime1, deployment_datetime2, deployment_datetime3].each {|d| create_deployment_dir(d)}

    assert_equal deployment_datetime3, @container.latest_deployment_datetime
  end

  def test_move_dependencies
=begin
    deployment_datetime1 = '2013-08-16_13-36-36.880'
    deployment_datetime2 = '2013-08-16_14-36-36.880'
    FileUtils.mkdir_p File.join(@test_dir, 'app-deployments', deployment_datetime1, 'dependencies')
    Dir.chdir(@runtime_dir) do
      FileUtils.ln_s(File.join(%W(.. .. app-deployments #{deployment_datetime1} dependencies)), 'dependencies')
    end
    FileUtils.mkdir_p File.join(@test_dir, 'app-deployments', deployment_datetime2, 'dependencies')
    File.new(File.join(@test_dir, 'app-deployments', deployment_datetime1, 'dependencies', 'abc'), "w")
    @container.move_dependencies(deployment_datetime2)
    refute_file_exist File.join(@test_dir, 'app-deployments', deployment_datetime1, 'dependencies', 'abc')
    assert_file_exist File.join(@test_dir, 'app-deployments', deployment_datetime2, 'dependencies', 'abc')
  end
=end
    @container.expects(:run_in_container_context).with("set -x; shopt -s dotglob; /bin/mv app-root/runtime/dependencies/* app-deployments/2013-08-16_13-36-36.880/dependencies",
                                                     chdir: @container.container_dir)

    @container.expects(:run_in_container_context).with("set -x; shopt -s dotglob; /bin/mv app-root/runtime/build-dependencies/* app-deployments/2013-08-16_13-36-36.880/build-dependencies",
                                                     chdir: @container.container_dir)

    @container.move_dependencies('2013-08-16_13-36-36.880')
  end

  def test_copy_dependencies
    @container.expects(:run_in_container_context).with("/bin/cp -a app-root/runtime/dependencies/. app-deployments/2013-08-16_13-36-36.880/dependencies",
                                                     chdir: @container.container_dir,
                                                     expected_exitstatus: 0)

    @container.expects(:run_in_container_context).with("/bin/cp -a app-root/runtime/build-dependencies/. app-deployments/2013-08-16_13-36-36.880/build-dependencies",
                                                     chdir: @container.container_dir,
                                                     expected_exitstatus: 0)

    @container.copy_dependencies('2013-08-16_13-36-36.880')
  end

  def test_current_deployment_datetime
    deployment_datetime = '2013-08-16_14-36-36.881'
    create_deployment_dir(deployment_datetime)
    Dir.chdir(@runtime_dir) do
      FileUtils.ln_s(File.join(%W(.. .. app-deployments #{deployment_datetime} repo)), 'repo')
    end

    assert_equal deployment_datetime, @container.current_deployment_datetime
  end

  def test_create_deployment_dir_no_current_deployment_no_force_clean_build
    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)
    Time.stubs(:now).returns(deployment_datetime)
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime_s)
    @container.expects(:set_rw_permission_R).with(deployment_dir)
    @container.expects(:current_deployment_datetime).returns(nil)

    created_datetime = @container.create_deployment_dir

    assert_equal created_datetime, deployment_datetime_s
    assert_path_exist deployment_dir
    assert_path_exist File.join(deployment_dir, 'repo')
    assert_path_exist File.join(deployment_dir, 'dependencies')

    assert_equal 0o40750, File.stat(deployment_dir).mode
    assert_equal 0o40750, File.stat(File.join(deployment_dir, 'repo')).mode
    assert_equal 0o40750, File.stat(File.join(deployment_dir, 'dependencies')).mode
  end

  def test_create_deployment_dir_keep_variable_undefined
    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)
    Time.stubs(:now).returns(deployment_datetime)
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime_s)
    @container.expects(:set_rw_permission_R).with(deployment_dir)

    current = time_to_s(deployment_datetime - 1.day)
    @container.expects(:current_deployment_datetime).returns(current).times(2)

    gear_env = {}
    ::OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns(gear_env)

    @container.expects(:move_dependencies).with(deployment_datetime_s)
    @container.expects(:clean_up_deployments_before).with(current)

    created_datetime = @container.create_deployment_dir

    assert_equal created_datetime, deployment_datetime_s
    assert_path_exist deployment_dir
    assert_path_exist File.join(deployment_dir, 'repo')
    assert_path_exist File.join(deployment_dir, 'dependencies')

    assert_equal 0o40750, File.stat(deployment_dir).mode
    assert_equal 0o40750, File.stat(File.join(deployment_dir, 'repo')).mode
    assert_equal 0o40750, File.stat(File.join(deployment_dir, 'dependencies')).mode
  end

  def test_create_deployment_dir_keep_multiple
    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)
    Time.stubs(:now).returns(deployment_datetime)
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime_s)
    @container.expects(:set_rw_permission_R).with(deployment_dir)

    current = time_to_s(deployment_datetime - 1.day)
    @container.expects(:current_deployment_datetime).returns(current)

    gear_env = {'OPENSHIFT_KEEP_DEPLOYMENTS' => "3"}
    ::OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns(gear_env)

    @container.expects(:copy_dependencies).with(deployment_datetime_s)

    created_datetime = @container.create_deployment_dir

    assert_equal created_datetime, deployment_datetime_s
    assert_path_exist deployment_dir
    assert_path_exist File.join(deployment_dir, 'repo')
    assert_path_exist File.join(deployment_dir, 'dependencies')

    assert_equal 0o40750, File.stat(deployment_dir).mode
    assert_equal 0o40750, File.stat(File.join(deployment_dir, 'repo')).mode
    assert_equal 0o40750, File.stat(File.join(deployment_dir, 'dependencies')).mode
  end

  def test_create_deployment_dir_force_clean_build
    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)
    Time.stubs(:now).returns(deployment_datetime)
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime_s)
    @container.expects(:set_rw_permission_R).with(deployment_dir)

    created_datetime = @container.create_deployment_dir(force_clean_build: true)

    assert_equal created_datetime, deployment_datetime_s
    assert_path_exist deployment_dir
    assert_path_exist File.join(deployment_dir, 'repo')
    assert_path_exist File.join(deployment_dir, 'dependencies')

    assert_equal 0o40750, File.stat(deployment_dir).mode
    assert_equal 0o40750, File.stat(File.join(deployment_dir, 'repo')).mode
    assert_equal 0o40750, File.stat(File.join(deployment_dir, 'dependencies')).mode
  end

  def test_calculate_deployment_id
    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime_s)

    @container.expects(:run_in_container_context).with("tar c . | tar xO | sha1sum | cut -f 1 -d ' '",
                                                       chdir: deployment_dir,
                                                       expected_exitstatus: 0)
                                                 .returns("a1b2c3d4e5f6")

    id = @container.calculate_deployment_id(deployment_datetime_s)

    assert_equal "a1b2c3d4", id
  end

  def test_deployment_metadata
    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime_s)
    create_deployment_dir(deployment_datetime_s)

    filename = 'myfile'
    myfile = File.join(deployment_dir, 'metadata', filename)

    data = 'mydata'

    refute_path_exist myfile

    @container.write_deployment_metadata(deployment_datetime_s, filename, data)

    assert_path_exist myfile
    assert_equal data, IO.read(myfile).chomp
    assert_equal data, @container.read_deployment_metadata(deployment_datetime_s, filename).chomp
  end

  def test_get_deployment_datetime_for_deployment_id
    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime_s)
    create_deployment_dir(deployment_datetime_s)

    deployment_id = 'abc12345'

    Dir.chdir(File.join(@test_dir, 'app-deployments', 'by-id')) do
      FileUtils.ln_s(File.join('..', deployment_datetime_s), deployment_id)
    end

    assert_equal deployment_datetime_s, @container.get_deployment_datetime_for_deployment_id(deployment_id)
  end

  def test_update_symlinks
    %w(repo dependencies).each do |dir|
      # make sure the link doesn't exist at first
      path = File.join(@runtime_dir, dir)
      refute_path_exist path

      # loop a few times to make sure the link is updated correctly
      3.times do
        deployment_datetime = Time.now
        deployment_datetime_s = time_to_s(deployment_datetime)
        deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime_s)
        create_deployment_dir(deployment_datetime_s)

        @container.send("update_#{dir}_symlink".to_sym, deployment_datetime_s)

        assert_path_exist path

        link_value = File.readlink(path)
        assert_equal "../../app-deployments/#{deployment_datetime_s}/#{dir}", link_value

        stat = File.lstat(path)
        assert_equal @user_uid, stat.uid.to_s
        assert_equal @user_uid, stat.gid.to_s
      end
    end
  end

  def test_delete_deployment_without_by_id_symlink
    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime_s)
    create_deployment_dir(deployment_datetime_s)

    assert_path_exist deployment_dir
    assert_empty Dir["#{File.join(@test_dir, 'app-deployments', 'by-id')}/*"]

    @container.delete_deployment(deployment_datetime_s)

    refute_path_exist deployment_dir
  end

  def test_delete_deployment_with_by_id_symlink
    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)
    deployment_dir = File.join(@container.container_dir, 'app-deployments', deployment_datetime_s)
    create_deployment_dir(deployment_datetime_s)

    deployment_id = 'abc12345'

    by_id_dir = File.join(@test_dir, 'app-deployments', 'by-id')
    Dir.chdir(by_id_dir) do
      FileUtils.ln_s(File.join('..', deployment_datetime_s), deployment_id)
    end

    assert_path_exist deployment_dir
    assert_path_exist File.join(by_id_dir, deployment_id)

    @container.delete_deployment(deployment_datetime_s)

    refute_path_exist deployment_dir
    refute_path_exist File.join(by_id_dir, deployment_id)
  end

  def test_clean_up_deployments_before_no_deployments
    gear_env = {}
    ::OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns(gear_env)
    @container.expects(:all_deployments).returns([]).times(2)

    @container.clean_up_deployments_before(time_to_s(Time.now))
  end

  # make sure it only keeps 1 deployment if OPENSHIFT_KEEP_DEPLOYMENTS is not defined
  def test_clean_up_deployments_before_keep_undefined
    gear_env = {}
    ::OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns(gear_env)

    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)

    deployments = %w(aaa bbb ccc).map {|e| "/var/lib/openshift/uuid/app-deployments/#{e}"}
    @container.expects(:all_deployments).returns(deployments).times(2)
    @container.expects(:read_deployment_metadata).returns('DEPLOYED').times(2)

    @container.expects(:delete_deployment).with('aaa')
    @container.expects(:delete_deployment).with('bbb')

    @container.clean_up_deployments_before('ccc')
  end

  # make sure it only keeps # of deployments specified by OPENSHIFT_KEEP_DEPLOYMENTS
  def test_clean_up_deployments_before_keep_defined
    gear_env = {'OPENSHIFT_KEEP_DEPLOYMENTS' => "2"}
    ::OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns(gear_env)

    deployment_datetime = Time.now
    deployment_datetime_s = time_to_s(deployment_datetime)

    deployments = %w(aaa bbb ccc).map {|e| "/var/lib/openshift/uuid/app-deployments/#{e}"}
    @container.expects(:all_deployments).returns(deployments).times(2)
    @container.expects(:read_deployment_metadata).returns('DEPLOYED').times(2)

    @container.expects(:delete_deployment).with('aaa')

    @container.clean_up_deployments_before('ccc')
  end

  # make sure it doesn't delete any deployments if we're under the limit
  def test_clean_up_deployments_under_keep_limit
    %w(3 4).each do |keep|
      gear_env = {'OPENSHIFT_KEEP_DEPLOYMENTS' => keep}
      ::OpenShift::Runtime::Utils::Environ.stubs(:for_gear).returns(gear_env)

      deployment_datetime = Time.now
      deployment_datetime_s = time_to_s(deployment_datetime)

      deployments = %w(aaa bbb ccc).map {|e| "/var/lib/openshift/uuid/app-deployments/#{e}"}
      @container.expects(:all_deployments).returns(deployments).times(2)
      @container.expects(:read_deployment_metadata).returns('DEPLOYED').times(2)

      @container.expects(:delete_deployment).never

      @container.clean_up_deployments_before('ccc')
    end
  end

  def test_archive
    current = time_to_s(Time.now)
    @container.expects(:current_deployment_datetime).returns(current)
    deployment_dir = PathUtils.join(@container.container_dir, 'app-deployments', current)
    @container.expects(:run_in_container_context).with("tar zcf - --exclude metadata .", 
                                                       has_entries(
                                                         chdir: deployment_dir,
                                                         expected_exitstatus: 0,
                                                         out: anything(),
                                                         err: anything()))
                                                 .returns("foo")

    output = @container.archive

    assert_equal 'foo', output
  end

  def test_archive_param
    current = time_to_s(Time.now)
    deployment_dir = PathUtils.join(@container.container_dir, 'app-deployments', current)
    @container.expects(:run_in_container_context).with("tar zcf - --exclude metadata .", 
                                                       has_entries(
                                                         chdir: deployment_dir,
                                                         expected_exitstatus: 0,
                                                         out: anything(),
                                                         err: anything()))
                                                 .returns("foo")

    output = @container.archive(current)

    assert_equal 'foo', output
  end

  def test_list_deployments
    deployment_datetime1 = '2013-08-16_13-36-36.880'
    deployment_datetime2 = '2013-08-16_14-36-36.880'
    deployment_datetime3 = '2013-08-16_15-36-36.881'
    @container.expects(:current_deployment_datetime).returns(deployment_datetime3)
    @container.expects(:all_deployments).returns([deployment_datetime1, deployment_datetime2, deployment_datetime3])
    @container.expects(:read_deployment_metadata).with(deployment_datetime3, 'id').returns("id3\n")
    @container.expects(:read_deployment_metadata).with(deployment_datetime3, 'state').returns("DEPLOYED\n")
    @container.expects(:read_deployment_metadata).with(deployment_datetime2, 'id').returns("id2\n")
    @container.expects(:read_deployment_metadata).with(deployment_datetime2, 'state').returns(nil)
    @container.expects(:read_deployment_metadata).with(deployment_datetime1, 'id').returns("id1\n")
    @container.expects(:read_deployment_metadata).with(deployment_datetime1, 'state').returns("DEPLOYED\n")
    output = @container.list_deployments
    expected = <<EOF
2013-08-16_15-36-36.881 - id3 - DEPLOYED - ACTIVE
2013-08-16_14-36-36.880 - id2 - NOT DEPLOYED
2013-08-16_13-36-36.880 - id1 - DEPLOYED
EOF
    assert_equal expected.chomp, output
  end

  def test_determine_extract_command_tar_gz
    %w(/tmp/foo.tar.gz /tmp/foo.tAr.Gz /tmp/FOO.TAR.GZ).each do |filename|
      assert_equal "/bin/tar xf #{filename}", @container.determine_extract_command(filename)
    end
  end

  def test_determine_extract_command_tar
    filename = '/tmp/foo.tar'
    assert_equal "/bin/tar xf #{filename}", @container.determine_extract_command(filename)
  end

  def test_determine_extract_command_zip
    filename = '/tmp/foo.zip'
    assert_equal "/usr/bin/unzip -q #{filename}", @container.determine_extract_command(filename)
  end

  def test_determine_extract_command_invalid
    filename = '/tmp/foo.bar'
    err = assert_raises(RuntimeError) { @container.determine_extract_command(filename)}
    assert_equal "Unable to determine file type for '#{filename}' - unable to deploy", err.message
  end

  def test_extract_deployment_archive_valid_file
    file_path = '/tmp/foo.tar.gz'

    File.expects(:exist?).with(file_path).returns(true)

    @container.expects(:determine_extract_command).with(file_path).returns('extract')

    gear_env = {'a' => 'b'}
    destination = '/bar'

    @container.expects(:run_in_container_context).with('extract',
                                                       env: gear_env,
                                                       chdir: destination,
                                                       expected_exitstatus: 0)

    @container.extract_deployment_archive(gear_env, file_path, destination)
  end

  def test_extract_deployment_archive_invalid_file
    file_path = '/tmp/foo.tar.gz'
    gear_env = {'a' => 'b'}
    destination = '/bar'

    File.expects(:exist?).with(file_path).returns(false)

    @container.expects(:determine_extract_command).never
    @container.expects(:run_in_container_context).never

    err = assert_raises(RuntimeError) { @container.extract_deployment_archive(gear_env, file_path, destination) }
    assert_equal "Specified file '#{file_path}' does not exist.", err.message
  end
end