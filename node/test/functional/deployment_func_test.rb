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

class DeploymentFuncTest < OpenShift::NodeTestCase
  GEAR_BASE_DIR = '/var/lib/openshift'

  #::OpenShift::Runtime::NodeLogger.disable

  def setup
    @uid = 5997

    @config.stubs(:get).with("GEAR_BASE_DIR").returns(GEAR_BASE_DIR)
    @config.stubs(:get).with("GEAR_GECOS").returns('Functional Test')
    @config.stubs(:get).with("CREATE_APP_SYMLINKS").returns('0')
    @config.stubs(:get).with("GEAR_SKEL_DIR").returns(nil)
    @config.stubs(:get).with("GEAR_SHELL").returns(nil)
    @config.stubs(:get).with("CLOUD_DOMAIN").returns('example.com')
    @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns('/etc/httpd/conf.d/openshift')
    @config.stubs(:get).with("PORT_BEGIN").returns(nil)
    @config.stubs(:get).with("PORT_END").returns(nil)
    @config.stubs(:get).with("PORTS_PER_USER").returns(5)
    @config.stubs(:get).with("UID_BEGIN").returns(@uid)
    @config.stubs(:get).with("BROKER_HOST").returns('localhost')
    @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns('.')

    @uuid = `uuidgen -r |sed -e s/-//g`.chomp

    begin
      %x(userdel -f #{Etc.getpwuid(@uid).name})
    rescue ArgumentError
    end

    @container = OpenShift::Runtime::ApplicationContainer.new(@uuid, @uuid, @uid, "AppRepoFuncTest", "AppRepoFuncTest", "functional-test")
    @container.create
  end

  def teardown
    unless ENV['PRESERVE']
      @container.destroy
    end
  end

  def assert_gear_user_owns_dir(dir)
    stat = File.stat(dir)
    assert_equal @uid, stat.uid
    assert_equal @uid, stat.gid
  end

  def validate_ownership(datetime)
    deployment_dir = File.join(@container.container_dir, 'app-deployments', datetime)
    assert_path_exist(deployment_dir)
    assert_gear_user_owns_dir(deployment_dir)

    repo_dir = File.join(deployment_dir, 'repo')
    assert_path_exist(repo_dir)
    assert_gear_user_owns_dir(repo_dir)

    dependencies_dir = File.join(deployment_dir, 'dependencies')
    assert_path_exist(dependencies_dir)
    assert_gear_user_owns_dir(dependencies_dir)
  end

  def test_create_deployment_dir
    datetime = @container.create_deployment_dir

    validate_ownership(datetime)

    # TODO can we assert dir permissions easily?
  end

  def test_configure_sets_up_dependencies_symlink
    datetime = @container.create_deployment_dir
    @container.configure('mock-0.1')
    link = File.readlink(File.join(@container.container_dir, 'app-root', 'runtime', 'dependencies'))
    link_datetime = File.basename(File.dirname(link))
    assert_equal datetime, link_datetime
  end

  def test_all_deployments
    # ApplicationContainer#create automatically creates a deployment directory.
    # If we try to create a new deployment dir and the timing is just "right",
    # it could end up being a no-op. We'll create 2 new deployment dirs,
    # sleeping in between, and we may end up with either 2 or 3 deployment dirs,
    # depending on timing
    datetime1 = @container.create_deployment_dir
    datetime2 = @container.create_deployment_dir

    deployments = @container.all_deployments

    # throw away and ingore the first entry if it was created as part of #create
    deployments.shift unless File.basename(deployments[0]) == datetime1

    assert deployments.size == 2
    assert_equal datetime1, File.basename(deployments[0])
    assert_equal datetime2, File.basename(deployments[1])
  end

  def test_latest_deployment_datetime
    datetime1 = @container.create_deployment_dir
    datetime2 = @container.create_deployment_dir
    assert_equal datetime2, @container.latest_deployment_datetime
  end

  def test_post_configure_no_build
    datetime = @container.latest_deployment_datetime
    @container.configure('mock-0.1')
    @container.post_configure('mock-0.1')

    # make sure the deployment id metadata file was created
    id_file = File.join(@container.container_dir, 'app-deployments', datetime, 'metadata', 'id')
    assert_path_exist(id_file)

    # read the deployment id
    deployment_id = IO.read(id_file).chomp

    # make sure the by-id symlink was created
    by_id_link_file = File.join(@container.container_dir, 'app-deployments', 'by-id', deployment_id)
    assert_path_exist(by_id_link_file)

    # make sure the by-id symlink points to the right datetime
    by_id_link = File.readlink(by_id_link_file)
    assert_equal datetime, File.basename(by_id_link)

    # validate repo symlink
    repo_link_file = File.join(@container.container_dir, 'app-root', 'runtime', 'repo')
    assert_path_exist(repo_link_file)
    repo_link = File.readlink(repo_link_file)
    assert_equal datetime, File.basename(File.dirname(repo_link))

    # validate deployment state metadata
    state_file = File.join(@container.container_dir, 'app-deployments', datetime, 'metadata', 'state')
    assert_path_exist(state_file)
    state = IO.read(state_file).chomp
    assert_equal 'DEPLOYED', state

    # validate ownership
    validate_ownership(datetime)
  end

  def test_current_deployment_datetime
    datetime = @container.create_deployment_dir
    @container.update_repo_symlink(datetime)
    assert_equal datetime, @container.current_deployment_datetime
  end

  def test_read_write_deployment_metadata
    datetime = @container.latest_deployment_datetime

    somefile = File.join(@container.container_dir, 'app-deployments', datetime, 'metadata', 'somefile')
    refute_path_exist(somefile)

    @container.write_deployment_metadata(datetime, 'somefile', 'hello')
    assert_path_exist(somefile)
    assert_equal 'hello', IO.read(somefile).chomp
    assert_equal 'hello', @container.read_deployment_metadata(datetime, 'somefile').chomp
  end

  def test_prepare_minimal
    datetime = @container.latest_deployment_datetime
    @container.configure('mock-0.1')
    @container.post_configure('mock-0.1')
    @container.build(deployment_datetime: datetime)
    @container.prepare(deployment_datetime: datetime)

    expected_deployment_id = '84ada878'

    # make sure the by-id symlink was created
    by_id_link_file = File.join(@container.container_dir, 'app-deployments', 'by-id', expected_deployment_id)
    assert_path_exist(by_id_link_file)

    # make sure the by-id symlink points to the right datetime
    by_id_link = File.readlink(by_id_link_file)
    assert_equal datetime, File.basename(by_id_link)

    # TODO may be better to just validate that it's an 8 character string
    assert_equal '84ada878', @container.read_deployment_metadata(datetime, 'id').chomp
  end

  def test_prepare_action_hook
    datetime = @container.latest_deployment_datetime
    @container.configure('mock-0.1')
    @container.post_configure('mock-0.1')
    @container.build(deployment_datetime: datetime)

    text = 'Hello from test_prepare_action_hook'

    repo_dir = File.join(@container.container_dir, 'app-deployments', datetime, 'repo')
    prepare_hook = File.join(repo_dir, '.openshift', 'action_hooks', 'prepare')
    File.open(prepare_hook, 'w', 0o0755) do |f|
      f.write <<END
#!/bin/bash
echo #{text} > #{repo_dir}/#{datetime}
END
    end
    PathUtils.oo_chown(@container.uuid, @container.uuid, prepare_hook)
    @container.prepare(deployment_datetime: datetime)
    assert_equal text, IO.read(File.join(repo_dir, datetime)).chomp
  end

  def test_prepare_file
    datetime = @container.latest_deployment_datetime
    @container.configure('mock-0.1')
    @container.post_configure('mock-0.1')

    tarfile = StringIO.new("")
    Gem::Package::TarWriter.new(tarfile) do |tar|
      tar.mkdir('repo', 0o0755)
      tar.add_file('repo/a', 0o0644) {|f| f.write("abc\n")}
      tar.mkdir('dependencies', 0o0755)
      tar.add_file('dependencies/b', 0o0644) {|f| f.write("def\n")}
    end
    gz = StringIO.new("")
    z = Zlib::GzipWriter.new(gz)
    z.write(tarfile.string)
    z.close
    gz = StringIO.new(gz.string)

    archive_file = File.join(@container.container_dir, 'app-archives', 'test.tar.gz')
    File.open(archive_file, 'wb') { |f| f.write(gz.string) }

    @container.prepare(deployment_datetime: datetime, file: 'test.tar.gz')
    a_file = File.join(@container.container_dir, 'app-deployments', datetime, 'repo', 'a')
    assert_path_exist(a_file)
    assert_equal "abc\n", IO.read(a_file)

    b_file = File.join(@container.container_dir, 'app-deployments', datetime, 'dependencies', 'b')
    assert_path_exist(b_file)
    assert_equal "def\n", IO.read(b_file)
  end
end