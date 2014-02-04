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
require 'pathname'
require 'securerandom'

# Deploy cannot be testing in this manner. SELinux requires a valid UID or the tests fail.
# See cucumber test application_repository.feature
class ApplicationRepositoryFuncTest < OpenShift::NodeTestCase
  GEAR_BASE_DIR = '/var/lib/openshift'

  def before_setup
    super
    @uid = 5997

    @config.stubs(:get).with("GEAR_BASE_DIR").returns(GEAR_BASE_DIR)
    @config.stubs(:get).with("GEAR_GECOS").returns('Functional Test')
    @config.stubs(:get).with("CREATE_APP_SYMLINKS").returns('0')
    @config.stubs(:get).with("GEAR_SKEL_DIR").returns(nil)
    @config.stubs(:get).with("GEAR_SHELL").returns('/usr/bin/oo-trap-user')
    @config.stubs(:get).with("CLOUD_DOMAIN").returns('example.com')
    @config.stubs(:get).with("OPENSHIFT_HTTP_CONF_DIR").returns('/etc/httpd/conf.d/openshift')
    @config.stubs(:get).with("PORT_BEGIN").returns(nil)
    @config.stubs(:get).with("PORT_END").returns(nil)
    @config.stubs(:get).with("PORTS_PER_USER").returns(5)
    @config.stubs(:get).with("UID_BEGIN").returns(@uid)
    @config.stubs(:get).with("BROKER_HOST").returns('localhost')
    @config.stubs(:get).with("CARTRIDGE_BASE_PATH").returns('.')
    @config.stubs(:get).with('REPORT_BUILD_ANALYTICS').returns(false)

    @uuid = SecureRandom.uuid.gsub(/-/, '')

    begin
      %x(userdel -f #{Etc.getpwuid(@uid).name})
    rescue ArgumentError
    end

    @container = OpenShift::Runtime::ApplicationContainer.new(@uuid, @uuid, @uid, "AppRepoFuncTest", "AppRepoFuncTest", "functional-test")
    @container.create(@secret_token)

    OpenShift::Runtime::CartridgeRepository.instance.clear
    OpenShift::Runtime::CartridgeRepository.instance.load

    @state = mock('::OpenShift::Runtime::Utils::ApplicationState')
    @state.stubs(:value=).with('started').returns('started')

    @hourglass = mock()
    @hourglass.stubs(:remaining).returns(3600)

    @model               = OpenShift::Runtime::V2CartridgeModel.new(@config, @container, @state, @hourglass)
    @cartridge_name      = 'mock-0.1'
    @cartridge_directory = 'mock'
    @cartridge_home      = File.join(@container.container_dir, @cartridge_directory)
    @model.configure(@cartridge_name)
    teardown
  end

  def after_teardown
    @container.destroy
  end

  def teardown
    FileUtils.rm_rf(File.join(@container.container_dir, @cartridge_directory, 'template'))
    FileUtils.rm_rf(File.join(@container.container_dir, @cartridge_directory, 'template.git'))
    FileUtils.rm_rf(File.join(@container.container_dir, @cartridge_directory, 'usr', 'template'))
    FileUtils.rm_rf(File.join(@container.container_dir, @cartridge_directory, 'usr', 'template.git'))
  end

  def assert_bare_repository(repo, empty=false)
    assert_path_exist repo.path
    assert_path_exist File.join(repo.path, 'description')
    assert_path_exist File.join(@container.container_dir, '.gitconfig')
    assert_path_exist File.join(repo.path, 'hooks', 'pre-receive')
    assert_path_exist File.join(repo.path, 'hooks', 'post-receive')

    files = Dir[repo.path + '/objects/**/*'].select{ |p| File.file?(p) }
    if empty
      assert_equal 0, files.count, "Error: Git repository should be empty"
    else
      assert files.count > 0, 'Error: Git repository missing objects'
    end
    files.each { |f|
      stat = File.stat(f)
      assert_equal @container.uid, stat.uid, 'Error: Git object wrong ownership'
    }

    stat = File.stat(File.join(repo.path, 'hooks'))
    assert_equal 0, stat.uid, 'Error: Git hook directory not owned by root'

    stat = File.stat(File.join(repo.path, 'hooks', 'post-receive'))
    assert_equal 0, stat.uid, 'Error: Git hook post-receive not owned by root'
  end

  def assert_repo_reset(repo)
    reflog = Dir.chdir(repo.path){ `git reflog | head -1` }
    assert reflog.include?("reset: moving to HEAD~1") || reflog.include?("HEAD~1: updating HEAD"), "Repository was not reset or reflog was not enabled (#{reflog})"
  end

  def test_new
    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    refute_nil repo
  end

  def test_no_template
    template = File.join(@container.container_dir, @cartridge_directory, 'template')
    FileUtils.rm_rf template
    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    refute_path_exist template
    runtime_repo = "#{@container.container_dir}/app-deployments/#{@container.latest_deployment_datetime}/repo"
    repo.archive(runtime_repo, 'master')
  end

  def test_bare_repository_usr
    create_template(File.join(@cartridge_home, 'usr', 'template', 'perl'))
    create_bare(File.join(@cartridge_home, 'usr', 'template'))

    cartridge_template_git = File.join(@cartridge_home, 'usr', 'template.git')
    assert_path_exist cartridge_template_git
    refute_path_exist File.join(@cartridge_home, 'usr', 'template')

    expected_path = File.join(@container.container_dir, 'git', @container.application_name + '.git')

    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    repo.destroy

    repo.populate_from_cartridge(@cartridge_directory)

    assert_equal expected_path, repo.path
    assert_bare_repository(repo)
    assert repo.exist?, "Application Repository (#{repo.path}) not found"
    assert repo.exists?, "Application Repository (#{repo.path}) not found"
  end

  def test_bare_repository
    create_template(File.join(@cartridge_home, 'template', 'perl'))
    create_bare(File.join(@cartridge_home, 'template'))

    cartridge_template_git = File.join(@cartridge_home, 'template.git')
    assert_path_exist cartridge_template_git
    refute_path_exist File.join(@cartridge_home, 'template')

    expected_path = File.join(@container.container_dir, 'git', @container.application_name + '.git')

    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    repo.destroy

    begin
      repo.populate_from_cartridge(@cartridge_directory)
    rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end

    assert_equal expected_path, repo.path
    assert_bare_repository(repo)
    assert repo.exist?, "Application Repository (#{repo.path}) not found"
    assert repo.exists?, "Application Repository (#{repo.path}) not found"
  end

  def test_from_url
    create_template(File.join(@cartridge_home, 'template', 'perl'))
    create_bare(File.join(@cartridge_home, 'template'))

    cartridge_template_git = File.join(@cartridge_home, 'template.git')
    assert_path_exist cartridge_template_git
    refute_path_exist File.join(@cartridge_home, 'template')
    cartridge_template_url = "file://#{cartridge_template_git}"

    expected_path = File.join(@container.container_dir, 'git', @container.application_name + '.git')

    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    repo.destroy

    begin
      repo.populate_from_url(@cartridge_name, cartridge_template_url)
    rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end

    assert_equal expected_path, repo.path
    assert_bare_repository(repo)
  end

  def test_from_ssh_url
    skip "Restore this test using webmock"
    #e = assert_raise(::OpenShift::Runtime::Utils::ShellExecutionException) do
    #  repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    #  repo.destroy
    #  repo.populate_from_url(@cartridge_name, 'git@github.com:jwhonce/origin-server.git')
    #end
    #
    #assert_equal expected_path, repo.path
    #assert_bare_repository(repo)
    #assert_repo_reset(repo)
  end

  def test_from_ssh_url_with_reset
    expected_path = File.join(@container.container_dir, 'git', @container.application_name + '.git')

    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    repo.destroy
    begin
      repo.populate_from_url(@cartridge_name, 'git://github.com/openshift/downloadable-mock.git#HEAD~1')
    rescue OpenShift::Runtime::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end    

    assert_equal expected_path, repo.path
    assert_bare_repository(repo)
    assert_repo_reset(repo)
  end  

  def test_source_usr
    refute_path_exist File.join(@cartridge_home, 'template.git')

    create_template(File.join(@cartridge_home, 'usr', 'template', 'perl'))
    expected_path = File.join(@container.container_dir, 'git', @container.application_name + '.git')

    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    repo.destroy
    refute_path_exist(expected_path)

    begin
      repo.populate_from_cartridge(@cartridge_directory)

      assert_equal expected_path, repo.path
      assert_bare_repository(repo)

      runtime_repo = "#{@container.container_dir}/app-deployments/#{@container.latest_deployment_datetime}/repo"
      repo.archive(runtime_repo, 'master')
      assert_path_exist File.join(runtime_repo, 'perl', 'health_check.pl')
    rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end
  end

  def test_source
    create_template(File.join(@cartridge_home, 'template', 'perl'))
    expected_path = File.join(@container.container_dir, 'git', @container.application_name + '.git')
    refute_path_exist File.join(@cartridge_home, 'template.git')

    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    repo.destroy
    refute_path_exist(expected_path)

    begin
      repo.populate_from_cartridge(@cartridge_directory)

      assert_equal expected_path, repo.path
      assert_bare_repository(repo)

      runtime_repo = "#{@container.container_dir}/app-deployments/#{@container.latest_deployment_datetime}/repo"
      repo.archive(runtime_repo, 'master')
      assert_path_exist File.join(runtime_repo, 'perl', 'health_check.pl')
    rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end
  end

  def test_empty_repository
    expected_path = File.join(@container.container_dir, 'git', @container.application_name + '.git')

    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    repo.destroy
    refute_path_exist(expected_path)

    begin
      repo.populate_empty(@cartridge_directory)

      assert_equal expected_path, repo.path
      assert_bare_repository(repo, true)

      runtime_repo = "#{@container.container_dir}/app-deployments/#{@container.latest_deployment_datetime}/repo"
      repo.archive(runtime_repo, 'master')
      assert_equal ['.', '..'].sort, Dir.entries(runtime_repo).sort
    rescue OpenShift::Runtime::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create empty git repo: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end
  end

  def test_bare_submodule
    create_template(File.join(@cartridge_home, 'template', 'perl'))
    create_bare_submodule
    expected_path = File.join(@container.container_dir, 'git', @container.application_name + '.git')

    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    repo.destroy
    refute_path_exist(expected_path)

    begin
      repo.populate_from_cartridge(@cartridge_directory)

      assert_equal expected_path, repo.path
      assert_bare_repository(repo)

      runtime_repo = "#{@container.container_dir}/app-deployments/#{@container.latest_deployment_datetime}/repo"
      repo.archive(runtime_repo, 'master')
      assert_path_exist File.join(runtime_repo, 'perl', 'health_check.pl')
      assert_path_exist File.join(runtime_repo, 'module001', 'README.md')
    rescue ::OpenShift::Runtime::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end
  end

  def test_bare_nested_submodule
    create_template(File.join(@cartridge_home, 'template', 'perl'))
    create_bare_nested_submodule
    expected_path = File.join(@container.container_dir, 'git', @container.application_name + '.git')

    repo = OpenShift::Runtime::ApplicationRepository.new(@container)
    repo.destroy
    refute_path_exist(expected_path)

    begin
      repo.populate_from_cartridge(@cartridge_directory)

      assert_equal expected_path, repo.path
      assert_bare_repository(repo)

      runtime_repo = "#{@container.container_dir}/app-deployments/#{@container.latest_deployment_datetime}/repo"
      repo.archive(runtime_repo, 'master')
      assert_path_exist File.join(runtime_repo, 'perl', 'health_check.pl')
      assert_path_exist File.join(runtime_repo, 'lib', 'module001', 'README.md')
      assert_path_exist File.join(runtime_repo, 'lib', 'module001', 'module002', 'README.md')
    rescue OpenShift::Runtime::Utils::ShellExecutionException => e
      puts %Q{
        Failed to create git repo from cartridge template: rc(#{e.rc})
        stdout ==> #{e.stdout}
        stderr ==> #{e.stderr}
           #{e.backtrace.join("\n")}}
      raise
    end
  end

  def create_template(path)
    # Cartridge Author tasks...
    #perl = File.join(@cartridge_home, 'template', 'perl')
    FileUtils.mkpath(path)

    File.open(File.join(path, 'health_check.pl'), 'w', 0664) { |f|
      f.write(%q{\
#!/usr/bin/perl
print "Content-type: text/plain\r\n\r\n";
print "1";
})
    }

    File.open(File.join(path, 'index.pl'), 'w', 0664) { |f|
      f.write(%q{\
#!/usr/bin/perl
print "Content-type: text/html\r\n\r\n";
print <<EOF
  <html>
    <head>
      <title>Welcome to OpenShift</title>
    </head>
    <body>
      <p>Welcome to OpenShift
    </body>
  </html>
EOF
})
      FileUtils.chown_R(@container.uid, @container.uid, path)
    }
  end

  def create_bare(template)
    Dir.chdir(@cartridge_home) do
      output = %x{set -xe;
pushd #{template};
git init;
git config user.email "mocker@example.com";
git config user.name "Mock Template builder";
git add -f .;
git </dev/null commit -a -m "Creating mocking template" 2>&1;
touch secondcommit
git add -f .;
git </dev/null commit -a -m "Second commit" 2>&1;
cd ..;
git </dev/null clone --bare --no-hardlinks template template.git 2>&1;
chown -R #{@container.uid}:#{@container.uid} template template.git;
popd;
}

      #puts "\ncreate_bare: #{output}"

      FileUtils.rm_r(template)
    end
  end

  def create_bare_submodule
    template  = File.join(@cartridge_home, 'template')
    submodule = File.join(@cartridge_home, 'module001')

    Dir.chdir(@cartridge_home) do
      output = %x{set -xe;
mkdir module001;
pushd module001;
git init;
git config user.email "module@example.com";
git config user.name "Mock Module builder";
touch README.md;
git add -f .;
git </dev/null commit -a -m "Creating module" 2>&1;
popd

pushd #{template}
git init;
git config user.email "mocker@example.com";
git config user.name "Mock Template builder";
git add -f .;
git </dev/null commit -a -m "Creating mocking template" 2>&1;
git submodule add #{submodule} module001
git submodule update --init
git </dev/null commit -m 'Added submodule module001'
popd;
git </dev/null clone --bare --no-hardlinks template template.git 2>&1;
chown -R #{@container.uid}:#{@container.uid} template template.git
}
      FileUtils.chown_R(@container.uid, @container.uid, template)
      #puts "\ncreate_bare_submodule: #{output}"

      FileUtils.rm_r(template)
    end
  end

  def create_bare_nested_submodule
    template  = File.join(@cartridge_home, 'template')
    submodule = File.join(@cartridge_home, 'module001')
    nested_submodule = File.join(@cartridge_home, 'module002')

    Dir.chdir(@cartridge_home) do
      output = %x{\
set -xe;

mkdir module002;
pushd module002;
git init;
git config user.email "module002@example.com";
git config user.name "Mock Module builder";
touch README.md;
git add -f .;
git </dev/null commit -a -m "Creating module002" 2>&1;
popd;

mkdir module001;
pushd module001;
git init;
git config user.email "module001@example.com";
git config user.name "Mock Module builder";
touch README.md;
git add -f .;
git submodule add #{nested_submodule} module002
git submodule update --init
git </dev/null commit -a -m "Creating module001" 2>&1;
popd;

pushd #{template}
git init;
git config user.email "mocker@example.com";
git config user.name "Mock Template builder";
touch README.md;
mkdir lib;
git add -f .;
git </dev/null commit -a -m "Creating mocking template" 2>&1;
git submodule add #{submodule} lib/module001
git submodule update --init
git </dev/null commit -m 'Added submodule module001'
popd;
git </dev/null clone --bare --no-hardlinks template template.git 2>&1;
chown -R #{@container.uid}:#{@container.uid} template template.git
}
      FileUtils.chown_R(@container.uid, @container.uid, template)
      #puts "\ncreate_bare_submodule: #{output}"

      FileUtils.rm_r(template)
    end
  end
end
